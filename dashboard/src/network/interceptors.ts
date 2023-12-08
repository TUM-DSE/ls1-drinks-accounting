import type {AxiosRequestConfig, AxiosResponse, InternalAxiosRequestConfig} from "axios";
import client from "@/network/client";
import { TokenService } from "@/network/tokenService";
import EventBus from "@/common/EventBus";

const setupInterceptor = () => {
  client.interceptors.request.use(
    (config: InternalAxiosRequestConfig) => {
      const token = TokenService.getToken();
      if (token) {
        (config.headers as unknown as Record<string, any>)[
          "Authorization"
        ] = `Bearer ${token.access_token}`;
      }
      return config;
    },
    (error: any) => {
      return Promise.reject(error);
    }
  );

  client.interceptors.response.use(
    (res: AxiosResponse) => {
      return res;
    },
    async (err: any) => {
      const originalConfig = err.config;

      if (originalConfig.url !== "/api/auth/login" && err.response) {
        // Access Token was expired
        if (err.response.status === 401 && !originalConfig._retry) {
          originalConfig._retry = true;
          let loginFailed = false;

          try {
            const credentials = TokenService.getAuthCredentials();
            if (!credentials) {
              loginFailed = true;
            } else {
              const rs = await client.post("/api/auth/login", {
                username: credentials.username,
                password: credentials.password,
              });

              const accessToken = rs.data;

              TokenService.saveToken(accessToken);

              if (!accessToken) {
                loginFailed = true;
              } else {
                return client(originalConfig);
              }
            }
          } catch (_error) {
            loginFailed = true;
          }

          if (loginFailed) {
            // window.location.replace("/login");
            EventBus.dispatch("logout", null);
            return Promise.reject();
          }
        }
      }

      return Promise.reject(err);
    }
  );
};

export default setupInterceptor;
