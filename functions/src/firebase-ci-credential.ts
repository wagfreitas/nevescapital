import axios from 'axios';

/**
 * Custom Firebase Admin credential that uses a Firebase CI refresh token.
 *
 * The CI token is obtained via `npx firebase login:ci` and is designed
 * for headless / CI environments. It uses the Firebase CLI's public
 * OAuth2 client to exchange the refresh token for short-lived access tokens.
 *
 * This avoids the need for a Service Account key file, which is blocked
 * by the org policy `constraints/iam.disableServiceAccountKeyCreation`.
 */
export class FirebaseCICredential {
  // Firebase CLI public OAuth2 client credentials (not secret — embedded in the CLI source)
  private static readonly CLIENT_ID =
    '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
  private static readonly CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';
  private static readonly TOKEN_URL = 'https://oauth2.googleapis.com/token';

  private cachedToken: { accessToken: string; expiresAt: number } | null = null;

  constructor(private readonly refreshToken: string) {}

  /**
   * Returns an access token, refreshing it if necessary.
   * Firebase Admin SDK calls this method automatically.
   */
  async getAccessToken(): Promise<{ access_token: string; expires_in: number }> {
    // Return cached token if still valid (with 5-min buffer)
    if (this.cachedToken && Date.now() < this.cachedToken.expiresAt - 5 * 60 * 1000) {
      const remainingSecs = Math.floor((this.cachedToken.expiresAt - Date.now()) / 1000);
      return { access_token: this.cachedToken.accessToken, expires_in: remainingSecs };
    }

    try {
      const response = await axios.post(
        FirebaseCICredential.TOKEN_URL,
        new URLSearchParams({
          grant_type: 'refresh_token',
          client_id: FirebaseCICredential.CLIENT_ID,
          client_secret: FirebaseCICredential.CLIENT_SECRET,
          refresh_token: this.refreshToken,
        }).toString(),
        { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } },
      );

      const { access_token, expires_in } = response.data;
      this.cachedToken = {
        accessToken: access_token,
        expiresAt: Date.now() + expires_in * 1000,
      };

      console.log(`🔑 Firebase CI token refreshed (expires in ${expires_in}s)`);
      return { access_token, expires_in };
    } catch (error: any) {
      const msg = error.response?.data?.error_description || error.message;
      console.error('❌ Falha ao renovar Firebase CI token:', msg);
      throw new Error(`Firebase CI credential refresh failed: ${msg}`);
    }
  }
}
