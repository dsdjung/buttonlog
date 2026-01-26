defmodule ButtonLogWeb.PrivacyLive do
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
          <h1 class="text-3xl font-bold text-gray-900 mb-6">Privacy Policy</h1>
          <p class="text-gray-500 text-sm mb-8">Last updated: January 2025</p>

          <div class="prose prose-gray max-w-none">
            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">1. Introduction</h2>
            <p class="text-gray-700 mb-4">
              ButtonLog ("we", "our", or "us") is committed to protecting your privacy. This
              Privacy Policy explains how we collect, use, and share information about you
              when you use our service.
            </p>

            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">2. Information We Collect</h2>
            <p class="text-gray-700 mb-4">
              We collect information you provide directly, including:
            </p>
            <ul class="list-disc pl-6 mb-4 text-gray-700">
              <li>Account information (email, username, display name)</li>
              <li>Button data and click history</li>
              <li>Profile information you choose to add</li>
              <li>Communications with us</li>
            </ul>

            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">3. How We Use Your Information</h2>
            <p class="text-gray-700 mb-4">
              We use your information to:
            </p>
            <ul class="list-disc pl-6 mb-4 text-gray-700">
              <li>Provide and maintain the ButtonLog service</li>
              <li>Process transactions and send related information</li>
              <li>Send you technical notices and support messages</li>
              <li>Respond to your comments and questions</li>
              <li>Improve and develop new features</li>
            </ul>

            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">4. Information Sharing</h2>
            <p class="text-gray-700 mb-4">
              We do not sell your personal information. We may share your information:
            </p>
            <ul class="list-disc pl-6 mb-4 text-gray-700">
              <li>With your consent</li>
              <li>With service providers who assist in our operations</li>
              <li>To comply with legal obligations</li>
              <li>To protect our rights and the rights of others</li>
            </ul>

            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">5. Data Security</h2>
            <p class="text-gray-700 mb-4">
              We implement appropriate technical and organizational measures to protect your
              personal information. However, no method of transmission over the Internet is
              100% secure.
            </p>

            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">6. Data Retention</h2>
            <p class="text-gray-700 mb-4">
              We retain your information for as long as your account is active or as needed
              to provide you with our services. You can request deletion of your data at any time.
            </p>

            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">7. Your Rights</h2>
            <p class="text-gray-700 mb-4">
              You have the right to:
            </p>
            <ul class="list-disc pl-6 mb-4 text-gray-700">
              <li>Access your personal information</li>
              <li>Correct inaccurate information</li>
              <li>Delete your account and data</li>
              <li>Export your data</li>
              <li>Opt out of marketing communications</li>
            </ul>

            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">8. Cookies and Tracking</h2>
            <p class="text-gray-700 mb-4">
              We use cookies and similar technologies to maintain your session and improve
              your experience. You can control cookies through your browser settings.
            </p>

            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">9. Children's Privacy</h2>
            <p class="text-gray-700 mb-4">
              ButtonLog is not intended for children under 13. We do not knowingly collect
              personal information from children under 13.
            </p>

            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">10. Changes to This Policy</h2>
            <p class="text-gray-700 mb-4">
              We may update this Privacy Policy from time to time. We will notify you of any
              changes by posting the new policy on this page.
            </p>

            <h2 class="text-xl font-semibold text-gray-900 mt-6 mb-3">11. Contact Us</h2>
            <p class="text-gray-700 mb-4">
              If you have any questions about this Privacy Policy, please contact us at
              <a href="mailto:privacy@buttonlog.app" class="text-teal-600 hover:text-teal-700">privacy@buttonlog.app</a>.
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
