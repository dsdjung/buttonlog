defmodule ButtonLogWeb.AuthController do
  use ButtonLogWeb, :controller
  alias ButtonLog.Accounts
  alias ButtonLog.Auth.Token

  plug Ueberauth

  def login_page(conn, _params) do
    render(conn, :login_page)
  end

  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        _token = Token.create_token(user.id)

        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: ~p"/buttons")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid email or password")
        |> render(:login_page)
    end
  end

  def register_page(conn, _params) do
    render(conn, :register_page)
  end

  def register(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Account created successfully!")
        |> redirect(to: ~p"/buttons")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Registration failed")
        |> render(:register_page, changeset: changeset)
    end
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "Logged out successfully")
    |> redirect(to: ~p"/auth/login")
  end

  # OAuth Methods
  def request(conn, %{"provider" => _provider} = params) do
    # Store mobile flag in session for the callback
    is_mobile = params["mobile"] == "true"

    conn =
      if is_mobile do
        put_session(conn, :oauth_mobile, true)
      else
        conn
      end

    # Ueberauth will handle the request automatically
    # This function won't be called directly due to Ueberauth plug
    conn
  end

  def callback(conn, %{"provider" => provider} = params) do
    # Check if this is a mobile OAuth request
    is_mobile = params["mobile"] == "true" || get_session(conn, :oauth_mobile) == true

    # Clear the mobile flag from session
    conn = delete_session(conn, :oauth_mobile)

    # Validate provider is one of the supported providers (safe, no atom conversion from user input)
    provider_atom = case provider do
      "google" -> :google
      "facebook" -> :facebook
      "apple" -> :apple
      _ -> nil
    end

    if is_nil(provider_atom) do
      handle_oauth_error(conn, "Invalid OAuth provider: #{provider}", is_mobile)
    else
      case Ueberauth.auth(conn) do
        %Ueberauth.Auth{provider: auth_provider} = auth when auth_provider == provider_atom ->
          case handle_oauth_callback(auth, provider) do
            {:ok, user} ->
              if is_mobile do
                # Generate JWT token for mobile and redirect to app
                token = Token.create_token(user.id)
                redirect(conn, external: "buttonlog://oauth?token=#{token}")
              else
                # Web flow - set session and redirect to buttons
                conn
                |> put_session(:user_id, user.id)
                |> put_flash(:info, "Successfully authenticated with #{provider}!")
                |> redirect(to: ~p"/buttons")
              end

            {:error, reason} ->
              handle_oauth_error(conn, "OAuth authentication failed: #{reason}", is_mobile)
          end

        %Ueberauth.Auth{provider: auth_provider} ->
          handle_oauth_error(conn, "OAuth provider mismatch: expected #{provider}, got #{auth_provider}", is_mobile)

        _other ->
          handle_oauth_error(conn, "OAuth authentication failed", is_mobile)
      end
    end
  end

  defp handle_oauth_error(conn, message, true = _is_mobile) do
    # Mobile error - redirect to app with error
    encoded_error = URI.encode(message)
    redirect(conn, external: "buttonlog://oauth?error=#{encoded_error}")
  end

  defp handle_oauth_error(conn, message, false = _is_mobile) do
    # Web error - flash and redirect to login
    conn
    |> put_flash(:error, message)
    |> redirect(to: ~p"/auth/login")
  end

  def delete(conn, %{"provider" => provider}) do
    # Remove OAuth provider association
    user_id = get_session(conn, :user_id)

    case Accounts.remove_oauth_provider(user_id, provider) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Successfully removed #{provider} authentication")
        |> redirect(to: ~p"/buttons")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to remove #{provider}: #{reason}")
        |> redirect(to: ~p"/buttons")
    end
  end

  # Private OAuth helper functions
  defp handle_oauth_callback(auth, provider) do
    Accounts.find_or_create_oauth_user(auth, provider)
  end
end
