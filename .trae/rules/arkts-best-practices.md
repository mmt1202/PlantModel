# ArkTS 最佳实践与常见错误

## 1. 最佳实践建议
- **始终定义接口**：为复杂对象定义明确接口，避免结构不清晰。
- **使用类型注解**：在函数参数和返回值中使用类型注解，提升代码可读性。
- **避免 any**：尽量避免使用 `any`，使用具体类型定义或 `unknown`。

## 2. 工具配置
在 `build-profile.json5` 中强制启用严格的类型检查：
```json
{
  "buildOption": {
    "arkOptions": {
      "strictMode": true
    }
  }
}
```

## 3. 常见错误及修复
- `Object literal must correspond to explicitly declared class`: 对象字面量缺少类型声明。
  **解决**：添加类型注解或使用临时变量显式定义。
- `Type 'unknown' is not assignable to type 'T'`: 类型推断失败。
  **解决**：明确指定具体类型。
- `Property 'x' does not exist on type 'object'`: 对象类型不明确。
  **解决**：定义具体的接口类型以取代基础的 `object` 声明。