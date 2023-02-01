import client from "@/network/client";
import { TokenService } from "@/network/tokenService";
import type { AuthCredentials } from "@/network/types/AuthCredentials";
import EventBus from "@/common/EventBus";

class AuthService {
  login(credentials: AuthCredentials): Promise<boolean> {
    return client
      .post("/api/auth/login", {
        username: credentials.username,
        password: credentials.password,
      })
      .then((response) => {
        if (response.data) {
          TokenService.saveToken(response.data);
          TokenService.saveCredentials(credentials);
          return true;
        } else {
          return false;
        }
      })
      .catch((e) => {
        if (e.response.status == 401) {
          return false;
        }

        throw e;
      });
  }

  logout() {
    TokenService.saveToken(null);
    TokenService.saveCredentials(null);
    EventBus.dispatch("logout", null);
  }

  isLoggedIn(): boolean {
    return TokenService.getToken() != null;
  }
}

export default new AuthService();
