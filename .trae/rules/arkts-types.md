# ArkTS 类型安全规范

## 1. 对象字面量类型声明
- **规则**：所有对象字面量必须对应明确声明的类或接口类型。
- **正例**：
  ```typescript
  return items.map((item): ResultInterface => {
    return { id: item.id, name: item.name };
  });
  ```
- **反例**：未明确指定返回类型的对象字面量，这会导致隐式类型推断错误。

## 2. 状态管理类型规范
- **规则**：`@State`、`@Prop`、`@Link` 装饰的变量必须有明确类型。
- **示例**：`@State searchResults: SearchResult[] = []`

## 3. 组件属性类型检查
- **规则**：组件所有属性和方法参数必须有明确类型定义。
- **示例**：
  ```typescript
  private performSearch(keyword: string): Promise<SearchResult[]> { ... }
  ```