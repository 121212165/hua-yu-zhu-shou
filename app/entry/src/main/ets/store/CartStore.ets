// 购物车持久化存储 - 基于 AppStorage + Preferences

import { BouquetScheme } from '../models/RecommendModel';
import { preferences } from '@kit.ArkData';

// 购物车项数据结构
export interface CartItem {
  scheme: BouquetScheme;
  quantity: number;
}

// 存储键名
const CART_STORAGE_KEY: string = 'cart_items';
const PREFERENCES_NAME: string = 'cart_prefs';

// 全局购物车状态（AppStorage 管理内存态，Preferences 管理持久化态）
export class CartStore {
  // ==================== 内存态操作（AppStorage） ====================

  // 初始化 AppStorage 中的购物车数据
  static initAppStorage(): void {
    if (!AppStorage.has('cartItems')) {
      AppStorage.setOrCreate<CartItem[]>('cartItems', []);
    }
    if (!AppStorage.has('cartTotalPrice')) {
      AppStorage.setOrCreate<number>('cartTotalPrice', 0);
    }
    if (!AppStorage.has('cartItemCount')) {
      AppStorage.setOrCreate<number>('cartItemCount', 0);
    }
  }

  // 获取购物车列表
  static getCartItems(): CartItem[] {
    return AppStorage.get<CartItem[]>('cartItems') || [];
  }

  // 设置购物车列表（同步更新总价和数量）
  static setCartItems(items: CartItem[]): void {
    AppStorage.set<CartItem[]>('cartItems', items);
    CartStore.updateSummary(items);
    CartStore.persistToDisk(items);
  }

  // 更新汇总信息（总价 + 总数量）
  private static updateSummary(items: CartItem[]): void {
    let totalPrice = 0;
    let itemCount = 0;
    for (const item of items) {
      totalPrice += item.scheme.totalPrice * item.quantity;
      itemCount += item.quantity;
    }
    AppStorage.set<number>('cartTotalPrice', totalPrice);
    AppStorage.set<number>('cartItemCount', itemCount);
  }

  // ==================== 购物车业务操作 ====================

  // 添加花束方案到购物车
  static addItem(scheme: BouquetScheme, quantity: number = 1): void {
    const items = CartStore.getCartItems();
    // 检查是否已存在相同方案
    const existingIndex = items.findIndex((item: CartItem) => item.scheme.id === scheme.id);
    if (existingIndex >= 0) {
      // 已存在则增加数量
      const updated = [...items];
      updated[existingIndex] = {
        ...updated[existingIndex],
        quantity: updated[existingIndex].quantity + quantity
      };
      CartStore.setCartItems(updated);
    } else {
      // 不存在则新增
      CartStore.setCartItems([...items, { scheme, quantity }]);
    }
  }

  // 更新指定项的数量
  static updateQuantity(index: number, quantity: number): void {
    const items = CartStore.getCartItems();
    if (index >= 0 && index < items.length && quantity >= 1) {
      const updated = [...items];
      updated[index] = { ...updated[index], quantity };
      CartStore.setCartItems(updated);
    }
  }

  // 增加指定项数量
  static increaseQuantity(index: number): void {
    const items = CartStore.getCartItems();
    if (index >= 0 && index < items.length && items[index].quantity < 99) {
      CartStore.updateQuantity(index, items[index].quantity + 1);
    }
  }

  // 减少指定项数量
  static decreaseQuantity(index: number): void {
    const items = CartStore.getCartItems();
    if (index >= 0 && index < items.length && items[index].quantity > 1) {
      CartStore.updateQuantity(index, items[index].quantity - 1);
    }
  }

  // 删除购物车项
  static removeItem(index: number): void {
    const items = CartStore.getCartItems();
    if (index >= 0 && index < items.length) {
      const updated = items.filter((_: CartItem, i: number) => i !== index);
      CartStore.setCartItems(updated);
    }
  }

  // 清空购物车
  static clearCart(): void {
    CartStore.setCartItems([]);
  }

  // 获取购物车总数量
  static getItemCount(): number {
    return AppStorage.get<number>('cartItemCount') || 0;
  }

  // 获取购物车总价
  static getTotalPrice(): number {
    return AppStorage.get<number>('cartTotalPrice') || 0;
  }

  // 判断购物车是否为空
  static isEmpty(): boolean {
    return CartStore.getItemCount() === 0;
  }

  // ==================== 持久化操作（Preferences） ====================

  // 从磁盘恢复购物车数据
  static async loadFromDisk(): Promise<void> {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, PREFERENCES_NAME);
      const cartJson = await prefs.get(CART_STORAGE_KEY, '[]') as string;
      const items = JSON.parse(cartJson) as CartItem[];
      // 写入 AppStorage 但不再次持久化（避免循环）
      AppStorage.set<CartItem[]>('cartItems', items);
      CartStore.updateSummary(items);
    } catch (error) {
      console.error('从磁盘恢复购物车失败:', JSON.stringify(error));
    }
  }

  // 将购物车数据写入磁盘
  private static async persistToDisk(items: CartItem[]): Promise<void> {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, PREFERENCES_NAME);
      await prefs.put(CART_STORAGE_KEY, JSON.stringify(items));
      await prefs.flush();
    } catch (error) {
      console.error('持久化购物车到磁盘失败:', JSON.stringify(error));
    }
  }
}
