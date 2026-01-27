defmodule ButtonLogWeb.TermsLive do
  use ButtonLogWeb, :live_view
  alias ButtonLog.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user = if session["user_id"], do: Accounts.get_user(session["user_id"]), else: nil
    {:ok, assign(socket, :current_user, current_user)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <div class="max-w-3xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
        <div class="bg-white rounded-lg shadow-md p-8">
          <h1 class="text-3xl font-bold text-gray-900 mb-6">Terms of Service</h1>
          <p class="text-gray-500 text-sm mb-8">Last updated: January 2026</p>

          <div class="prose prose-gray max-w-none">
            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">1. Acceptance of Terms</h2>
            <p class="text-gray-700 mb-4">
              By accessing or using ButtonLog, you agree to be bound by these Terms of Service.
              If you do not agree to these terms, please do not use our service.
            </p>

            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">2. Description of Service</h2>
            <p class="text-gray-700 mb-4">
              ButtonLog is a button tracking application that allows users to track activities,
              habits, and events through customizable buttons. The service includes mobile
              applications and a web interface.
            </p>

            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">3. User Accounts</h2>
            <p class="text-gray-700 mb-4">
              To use ButtonLog, you must create an account. You are responsible for maintaining
              the confidentiality of your account credentials and for all activities that occur
              under your account.
            </p>

            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">4. User Content</h2>
            <p class="text-gray-700 mb-4">
              You retain ownership of any content you create using ButtonLog. By using our
              service, you grant us a license to store and process your content as necessary
              to provide the service.
            </p>

            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">5. Acceptable Use</h2>
            <p class="text-gray-700 mb-4">
              You agree not to use ButtonLog for any unlawful purpose or in any way that could
              damage, disable, or impair the service. You must not attempt to gain unauthorized
              access to any part of the service.
            </p>

            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">6. Subscription and Payments</h2>
            <p class="text-gray-700 mb-4">
              ButtonLog offers free and premium subscription tiers. Premium features require
              a paid subscription. Subscription fees are billed in advance and are non-refundable
              except as required by law.
            </p>

            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">7. Termination</h2>
            <p class="text-gray-700 mb-4">
              We may terminate or suspend your account at any time for violations of these terms.
              You may delete your account at any time through the application settings.
            </p>

            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">8. Disclaimer of Warranties</h2>
            <p class="text-gray-700 mb-4">
              ButtonLog is provided "as is" without warranties of any kind, either express or
              implied. We do not guarantee that the service will be uninterrupted or error-free.
            </p>

            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">9. Limitation of Liability</h2>
            <p class="text-gray-700 mb-4">
              To the maximum extent permitted by law, ButtonLog shall not be liable for any
              indirect, incidental, special, or consequential damages arising from your use
              of the service.
            </p>

            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">10. Changes to Terms</h2>
            <p class="text-gray-700 mb-4">
              We may update these terms from time to time. We will notify you of any material
              changes by posting the new terms on this page and updating the "Last updated" date.
            </p>

            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">11. Contact Us</h2>
            <p class="text-gray-700 mb-4">
              If you have any questions about these Terms of Service, please contact us at
              <a href="mailto:support@buttonlog.com" class="text-teal-600 hover:text-teal-700">support@buttonlog.com</a>.
            </p>
          </div>

          <div class="mt-8 pt-6 border-t border-gray-200">
            <a href="/" class="text-teal-600 hover:text-teal-700">Back to Home</a>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
