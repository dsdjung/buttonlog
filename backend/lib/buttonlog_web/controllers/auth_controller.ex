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
  def request(conn, %{"provider" => provider}) do
    IO.puts "=== OAUTH REQUEST DEBUG ==="
    IO.puts "Provider: #{provider}"
    IO.puts "Conn: #{inspect(conn)}"
    IO.puts "==========================="

    # Ueberauth will handle the request automatically
    # This function won't be called directly due to Ueberauth plug
    conn
  end

    def callback(conn, %{"provider" => provider}) do
    IO.puts "=== OAUTH CALLBACK DEBUG ==="
    IO.puts "Provider: #{provider}"
    IO.puts "Conn params: #{inspect(conn.params)}"
    IO.puts "============================="

    case Ueberauth.auth(conn) do
      %Ueberauth.Auth{provider: auth_provider, info: info, credentials: credentials, uid: uid} = auth ->
        # Convert provider string to atom for comparison
        provider_atom = String.to_existing_atom(provider)

        if auth_provider == provider_atom do
        IO.puts "=== OAUTH AUTH DATA ==="
        IO.puts "Provider: #{auth.provider}"
        IO.puts "UID: #{uid}"
        IO.puts "Info: #{inspect(info)}"
        IO.puts "Credentials: #{inspect(credentials)}"
        IO.puts "========================"

                  case handle_oauth_callback(auth, provider) do
            {:ok, user} ->
              IO.puts "=== OAUTH SUCCESS ==="
              IO.puts "User object: #{inspect(user)}"
              IO.puts "User username: #{user.username}"
              IO.puts "User email: #{user.email}"
              IO.puts "====================="

              conn
              |> put_session(:user_id, user.id)
              |> put_flash(:info, "Successfully authenticated with #{provider}!")
              |> redirect(to: ~p"/buttons")

            {:error, reason} ->
              IO.puts "=== OAUTH ERROR ==="
              IO.puts "Error: #{reason}"
              IO.puts "==================="

              conn
              |> put_flash(:error, "OAuth authentication failed: #{reason}")
              |> redirect(to: ~p"/auth/login")
          end
        else
          IO.puts "=== OAUTH PROVIDER MISMATCH ==="
          IO.puts "Expected provider: #{provider} (#{provider_atom})"
          IO.puts "Actual provider: #{auth_provider}"
          IO.puts "================================"

          conn
          |> put_flash(:error, "OAuth provider mismatch")
          |> redirect(to: ~p"/auth/login")
        end

      other ->
        IO.puts "=== OAUTH UNEXPECTED ==="
        IO.puts "Unexpected auth result: #{inspect(other)}"
        IO.puts "========================"

        conn
        |> put_flash(:error, "OAuth authentication failed")
        |> redirect(to: ~p"/auth/login")
    end
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
    IO.puts "=== HANDLE OAUTH CALLBACK DEBUG ==="
    IO.puts "Provider: #{provider}"
    IO.puts "Auth UID: #{auth.uid}"
    IO.puts "Auth email: #{auth.info.email}"
    IO.puts "================================"

    result = Accounts.find_or_create_oauth_user(auth, provider)
    IO.puts "=== OAUTH RESULT ==="
    IO.puts "Result: #{inspect(result)}"
    IO.puts "==================="

    result
  end
end
