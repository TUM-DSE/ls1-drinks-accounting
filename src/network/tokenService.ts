import type {AccessToken} from "@/network/types/AccessToken";
import type {AuthCredentials} from "@/network/types/AuthCredentials";

export class TokenService {
  static getToken(): AccessToken | null {
    const token = localStorage.getItem("access-token");
    if (!token) {
      return null;
    }

    return JSON.parse(token);
  }

  static saveToken(accessToken: AccessToken | null) {
    if (accessToken) {
      localStorage.setItem("access-token", JSON.stringify(accessToken));
    } else {
      localStorage.removeItem("access-token");
    }
  }

  static getAuthCredentials(): AuthCredentials | null {
    const credentials = localStorage.getItem("credentials");
    if (!credentials) {
      return null;
    }

    return JSON.parse(credentials);
  }

  static saveCredentials(credentials: AuthCredentials | null) {
    if (credentials) {
      localStorage.setItem("credentials", JSON.stringify(credentials));
    } else {
      localStorage.removeItem("credentials");
    }
  }
}
