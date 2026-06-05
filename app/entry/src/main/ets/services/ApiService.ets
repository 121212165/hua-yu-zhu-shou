// API接口定义 - 所有后端API接口

import { HttpUtil } from './HttpUtil';
import { LoginParams, LoginResponse, RegisterParams, RegisterResponse, RecipientInfo, CreateRecipientParams } from '../models/UserModel';
import { FlowerInfo, GetFlowersParams, GetFlowersResponse } from '../models/FlowerModel';
import { GenerateRecommendationParams, RecommendationResponse, CreateOrderParams, OrderInfo, OrderListResponse, UpdateOrderStatusParams, SubmitFeedbackParams, FeedbackInfo } from '../models/RecommendModel';

export class ApiService {
  // ==================== 用户认证 ====================

  // 登录
  static async login(params: LoginParams): Promise<LoginResponse> {
    const response = await HttpUtil.post<LoginResponse>('/auth/login', params);
    // 登录成功后保存Token
    if (response.data.token) {
      await HttpUtil.saveToken(response.data.token);
    }
    return response.data;
  }

  // 注册
  static async register(params: RegisterParams): Promise<RegisterResponse> {
    const response = await HttpUtil.post<RegisterResponse>('/auth/register', params);
    // 注册成功后保存Token
    if (response.data.token) {
      await HttpUtil.saveToken(response.data.token);
    }
    return response.data;
  }

  // ==================== 花材相关 ====================

  // 获取花材列表
  static async getFlowers(params?: GetFlowersParams): Promise<GetFlowersResponse> {
    const queryParams: Record<string, string | number> = {};
    if (params) {
      if (params.category) queryParams['category'] = params.category;
      if (params.color) queryParams['color'] = params.color;
      if (params.keyword) queryParams['keyword'] = params.keyword;
      if (params.page) queryParams['page'] = params.page;
      if (params.pageSize) queryParams['pageSize'] = params.pageSize;
    }
    const response = await HttpUtil.get<GetFlowersResponse>('/flowers', queryParams);
    return response.data;
  }

  // 获取花材详情
  static async getFlowerDetail(id: number): Promise<FlowerInfo> {
    const response = await HttpUtil.get<FlowerInfo>(`/flowers/${id}`);
    return response.data;
  }

  // ==================== 收件人相关 ====================

  // 获取收件人列表
  static async getRecipients(): Promise<RecipientInfo[]> {
    const response = await HttpUtil.get<RecipientInfo[]>('/recipients', undefined, true);
    return response.data;
  }

  // 创建收件人
  static async createRecipient(params: CreateRecipientParams): Promise<RecipientInfo> {
    const response = await HttpUtil.post<RecipientInfo>('/recipients', params, true);
    return response.data;
  }

  // ==================== 推荐相关 ====================

  // 生成推荐方案
  static async generateRecommendation(params: GenerateRecommendationParams): Promise<RecommendationResponse> {
    const response = await HttpUtil.post<RecommendationResponse>('/recommendations/generate', params, true);
    return response.data;
  }

  // 获取推荐历史
  static async getRecommendationHistory(page: number = 1, pageSize: number = 10): Promise<RecommendationResponse[]> {
    const response = await HttpUtil.get<RecommendationResponse[]>('/recommendations/history', { page, pageSize }, true);
    return response.data;
  }

  // ==================== 订单相关 ====================

  // 创建订单
  static async createOrder(params: CreateOrderParams): Promise<OrderInfo> {
    const response = await HttpUtil.post<OrderInfo>('/orders', params, true);
    return response.data;
  }

  // 获取订单列表（支持状态筛选）
  static async getOrders(page: number = 1, pageSize: number = 10, status?: string): Promise<OrderListResponse> {
    const params: Record<string, string | number> = { page, pageSize };
    if (status) {
      params['status'] = status;
    }
    const response = await HttpUtil.get<OrderListResponse>('/orders', params, true);
    return response.data;
  }

  // 获取订单详情
  static async getOrderDetail(id: string): Promise<OrderInfo> {
    const response = await HttpUtil.get<OrderInfo>(`/orders/${id}`, undefined, true);
    return response.data;
  }

  // 更新订单状态
  static async updateOrderStatus(id: string, status: string): Promise<OrderInfo> {
    const response = await HttpUtil.put<OrderInfo>(`/orders/${id}/status`, { status }, true);
    return response.data;
  }

  // 取消订单
  static async cancelOrder(id: string): Promise<OrderInfo> {
    const response = await HttpUtil.put<OrderInfo>(`/orders/${id}/cancel`, undefined, true);
    return response.data;
  }

  // ==================== 反馈相关 ====================

  // 提交反馈
  static async submitFeedback(params: SubmitFeedbackParams): Promise<FeedbackInfo> {
    const response = await HttpUtil.post<FeedbackInfo>('/feedbacks', params, true);
    return response.data;
  }

  // 获取反馈历史
  static async getFeedbackHistory(page: number = 1, pageSize: number = 10): Promise<FeedbackInfo[]> {
    const response = await HttpUtil.get<FeedbackInfo[]>('/feedbacks', { page, pageSize }, true);
    return response.data;
  }
}