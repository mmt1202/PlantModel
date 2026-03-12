# ArkTS 代码规范和最佳实践

## 类型安全规则

### 1. 对象字面量类型声明 (arkts-no-untyped-obj-literals)

**规则说明：**  所有对象字面量必须对应明确声明的类或接口类型。

**错误示例：**

​```typescript
// ❌ 错误：未明确指定返回类型的对象字面量
return items.map((item) => ({
  id: item.id,
  name: item.name,
  type: "example",
}));
​```

**正确示例：**

​```typescript
// ✅ 正确：明确指定返回类型
return items.map((item): ResultInterface => {
  return {
    id: item.id,
    name: item.name,
    type: "example",
  };
});

// 或者使用临时变量
return items.map((item) => {
  const result: ResultInterface = {
    id: item.id,
    name: item.name,
    type: "example",
  };
  return result;
});
​```

**适用场景：**
- map、filter、reduce 等数组方法的回调函数
-  函数返回值
-  变量赋值
-  参数传递

**修复方法：**
1.  为箭头函数添加明确的返回类型注解
2.  使用临时变量并声明类型
3.  确保接口或类型定义存在且可访问

### 2. 状态管理类型规范

**规则说明：** @State、@Prop、@Link 装饰的变量必须有明确的类型声明。

**示例：**

​```typescript
// ✅ 正确
@State searchResults: SearchResult[] = []
@Prop title: string = ''
@Link selectedIndex: number
​```

### 3. 组件属性类型检查

**规则说明：**  组件的所有属性和方法参数必须有明确的类型定义。

**示例：**

​```typescript
// ✅ 正确
private performSearch(keyword: string): Promise<SearchResult[]> {
  // 实现
}

private onItemClick(item: SearchResult): void {
  // 实现
}
​```

## 最佳实践建议

1. **始终定义接口：**  为复杂对象定义明确的接口
2. **使用类型注解：**  在函数参数和返回值中使用类型注解
3. **避免 any 类型：**  尽量避免使用 any，使用具体的类型定义
4. **类型导入：**  确保所需的类型和接口正确导入

## 工具配置

在  `build-profile.json5`  中启用严格的类型检查：

​```json
{
  "buildOption": {
    "arkOptions": {
      "strictMode": true
    }
  }
}
​```

## 常见错误和解决方案

| 错误信息                                                                          | 原因                   | 解决方案                   |
| --------------------------------------------------------------------------------- | ---------------------- | -------------------------- |
|  `Object literal must correspond to some explicitly declared class or interface`  | 对象字面量缺少类型声明 | 添加类型注解或使用临时变量 |
|  `Type 'unknown' is not assignable to type 'T'`                                   | 类型推断失败           | 明确指定类型               |
|  `Property 'x' does not exist on type 'object'`                                   | 对象类型不明确         | 定义具体的接口类型         |

---
