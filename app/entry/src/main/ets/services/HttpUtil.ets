// HTTP请求封装 - 基于@ohos.net.http模块

import http from '@ohos.net.http';
import { BASE_URL, HTTP_TIMEOUT, TOKEN_KEY } from '../utils/Constants';
import { preferences } from '@ohos.data.preferences';

// 通用响应结构
export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}

// HTTP方法枚举
export enum HttpMethod {
  GET = 'GET',
  POST = 'POST',
  PUT = 'PUT',
  DELETE = 'DELETE'
}

// 请求选项
interface RequestOptions {
  url: string;
  method: HttpMethod;
  data?: object;
  headers?: Record<string, string>;
  needAuth?: boolean;
}

export class HttpUtil {
  // 获取存储的Token
  static async getToken(): Promise<string> {
    try {
      const context = getContext(this);
      const pref = await preferences.getContext(context, 'flower_app_prefs');
      return pref.get(TOKEN_KEY, '') as string;
    } catch (error) {
      return '';
    }
  }

  // 保存Token
  static async saveToken(token: string): Promise<void> {
    try {
      const context = getContext(this);
      const pref = await preferences.getContext(context, 'flower_app_prefs');
      await pref.put(TOKEN_KEY, token);
      await pref.flush();
    } catch (error) {
      console.error('保存Token失败:', JSON.stringify(error));
    }
  }

  // 清除Token
  static async clearToken(): Promise<void> {
    try {
      const context = getContext(this);
      const pref = await preferences.getContext(context, 'flower_app_prefs');
      await pref.delete(TOKEN_KEY);
      await pref.flush();
    } catch (error) {
      console.error('清除Token失败:', JSON.stringify(error));
    }
  }

  // 统一请求方法
  static async request<T>(options: RequestOptions): Promise<ApiResponse<T>> {
    const httpRequest = http.createHttp();

    try {
      // 构建请求头
      const headers: Record<string, string> = {
        'Content-Type': 'application/json',
        ...options.headers
      };

      // 如果需要认证，添加Authorization头
      if (options.needAuth) {
        const token = await HttpUtil.getToken();
        if (token) {
          headers['Authorization'] = `Bearer ${token}`;
        }
      }

      // 构建完整URL
      const fullUrl = options.url.startsWith('http') ? options.url : `${BASE_URL}${options.url}`;

      // 发起请求
      const response = await httpRequest.request(fullUrl, {
        method: options.method,
        header: headers,
        extraData: options.data ? JSON.stringify(options.data) : undefined,
        connectTimeout: HTTP_TIMEOUT,
        readTimeout: HTTP_TIMEOUT
      });

      // 处理响应
      if (response.responseCode === 200 || response.responseCode === 201) {
        const result: ApiResponse<T> = JSON.parse(response.result as string);
        if (result.code === 0 || result.code === 200) {
          return result;
        } else {
          throw new Error(`业务错误: ${result.message}`);
        }
      } else if (response.responseCode === 401) {
        // Token过期，清除本地存储
        await HttpUtil.clearToken();
        throw new Error('登录已过期，请重新登录');
      } else {
        throw new Error(`HTTP错误: ${response.responseCode}`);
      }
    } catch (error) {
      console.error(`请求失败 [${options.method} ${options.url}]:`, JSON.stringify(error));
      throw error;
    } finally {
      httpRequest.destroy();
    }
  }

  // GET请求
  static async get<T>(url: string, params?: Record<string, string | number>, needAuth: boolean = false): Promise<ApiResponse<T>> {
    // 将params拼接到URL
    let fullUrl = url;
    if (params) {
      const queryParts: string[] = [];
      for (const key in params) {
        if (params[key] !== undefined && params[key] !== null) {
          queryParts.push(`${key}=${encodeURIComponent(String(params[key]))}`);
        }
      }
      if (queryParts.length > 0) {
        fullUrl += `?${queryParts.join('&')}`;
      }
    }

    return HttpUtil.request<T>({
      url: fullUrl,
      method: HttpMethod.GET,
      needAuth: needAuth
    });
  }

  // POST请求
  static async post<T>(url: string, data?: object, needAuth: boolean = false): Promise<ApiResponse<T>> {
    return HttpUtil.request<T>({
      url: url,
      method: HttpMethod.POST,
      data: data,
      needAuth: needAuth
    });
  }

  // PUT请求
  static async put<T>(url: string, data?: object, needAuth: boolean = true): Promise<ApiResponse<T>> {
    return HttpUtil.request<T>({
      url: url,
      method: HttpMethod.PUT,
      data: data,
      needAuth: needAuth
    });
  }

  // DELETE请求
  static async delete<T>(url: string, needAuth: boolean = true): Promise<ApiResponse<T>> {
    return HttpUtil.request<T>({
      url: url,
      method: HttpMethod.DELETE,
      needAuth: needAuth
    });
  }
}