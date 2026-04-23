# TypeScript ESLint 通用规则规范

## 1. 推荐规则集
### 1.1 `@typescript-eslint/recommended`
- **规则说明**：启用 `@typescript-eslint` 官方推荐规则集，作为 TypeScript 项目的基础代码质量约束。
- **适用建议**：
  - 新项目默认启用，作为统一的静态检查基线。
  - 与严格类型检查配合使用，减少隐式错误和不安全写法。

## 2. 异步与边界类型规则
### 2.1 `@typescript-eslint/await-thenable`
- **规则说明**：不允许对非 Thenable 值使用 `await`。
- **约束**：
  - 仅对 `Promise` 或实现了 `then()` 方法的对象使用 `await`。
  - 对同步函数返回值禁止直接 `await`，避免误导性代码。

### 2.2 `@typescript-eslint/explicit-function-return-type`
- **规则说明**：函数和类方法必须显式声明返回类型。
- **约束**：
  - 普通函数、箭头函数、类方法都应补充返回类型。
  - 避免依赖复杂推导结果，提高可读性和重构安全性。

### 2.3 `@typescript-eslint/explicit-module-boundary-types`
- **规则说明**：所有导出函数、公共类方法及模块边界成员必须显式声明参数类型和返回类型。
- **约束**：
  - 对外暴露的 API 禁止依赖隐式推断。
  - 公共方法的入参与返回值必须具备稳定、可审查的类型定义。

## 3. 类型导入与类型约束规则
### 3.1 `@typescript-eslint/consistent-type-imports`
- **规则说明**：统一类型导入风格，推荐使用 `import type` 导入纯类型。
- **约束**：
  - 类型和运行时值应明确区分，避免混合导入。
  - 纯类型引用统一使用 `import type`，提升可读性和构建优化能力。

### 3.2 `@typescript-eslint/no-unnecessary-type-constraint`
- **规则说明**：禁止在泛型中添加无意义的约束条件。
- **约束**：
  - 如无实际限制需求，不要写 `T extends unknown`、`T extends any`。
  - 泛型约束必须服务于属性访问、方法调用或类型收窄需求。

## 4. 类型安全高风险规则
### 4.1 `@typescript-eslint/no-explicit-any`
- **规则说明**：禁止显式使用 `any` 类型。
- **约束**：
  - 优先使用明确接口、联合类型、泛型或 `unknown`。
  - 必须避免用 `any` 绕过类型系统。

### 4.2 `@typescript-eslint/no-unsafe-argument`
- **规则说明**：禁止将 `any` 类型值作为函数参数传入。
- **约束**：
  - 参数传递前必须完成类型校验或显式收窄。
  - 对外部输入数据应先解析再使用。

### 4.3 `@typescript-eslint/no-unsafe-assignment`
- **规则说明**：禁止将 `any` 类型值赋值给变量、对象属性或结构化目标。
- **约束**：
  - 接收不可信数据时，优先定义中间类型或使用校验函数。
  - 禁止将未确认类型的数据直接注入业务状态。

### 4.4 `@typescript-eslint/no-unsafe-call`
- **规则说明**：禁止调用 `any` 类型表达式。
- **约束**：
  - 调用前必须确认目标是可调用类型。
  - 对动态函数引用应先进行类型守卫。

### 4.5 `@typescript-eslint/no-unsafe-member-access`
- **规则说明**：禁止访问 `any` 类型值的成员。
- **约束**：
  - 属性读取前必须完成类型收窄或断言到明确接口。
  - 外部 JSON、接口响应、存储读取结果都不应直接点取属性。

### 4.6 `@typescript-eslint/no-unsafe-return`
- **规则说明**：函数禁止返回 `any` 类型值。
- **约束**：
  - 返回前应转换为明确类型，或使用受控的 `unknown` + 校验流程。
  - 导出函数尤其要避免将不安全值直接透出。

## 5. 循环、对象与上下文规则
### 5.1 `@typescript-eslint/no-dynamic-delete`
- **规则说明**：不允许对 computed key 表达式使用 `delete`。
- **约束**：
  - 禁止使用 `delete obj[key]` 这类动态删除方式。
  - 如需移除字段，优先构造新对象或使用受控映射结构。

### 5.2 `@typescript-eslint/no-for-in-array`
- **规则说明**：禁止使用 `for...in` 遍历数组。
- **约束**：
  - 数组遍历应使用 `for...of`、普通 `for`、`forEach`、`map` 等方式。
  - 避免把数组索引当作字符串键处理，防止继承属性干扰。

### 5.3 `@typescript-eslint/no-this-alias`
- **规则说明**：禁止将 `this` 赋值给其他变量。
- **约束**：
  - 禁止使用 `const self = this`、`const that = this` 等写法。
  - 优先使用箭头函数保持 `this` 语义一致。

## 6. 枚举规则
### 6.1 `@typescript-eslint/prefer-literal-enum-member`
- **规则说明**：要求所有枚举成员使用字面量值定义。
- **约束**：
  - 枚举成员应显式写为字符串字面量或数字字面量。
  - 避免使用复杂表达式初始化枚举值，确保可读性与稳定性。

## 7. 实施建议
1. **默认基线**：所有 TypeScript 项目默认启用 `@typescript-eslint/recommended`。
2. **严格类型**：建议与 `strict: true` 一起使用，最大化类型系统收益。
3. **边界控制**：对 API 层、状态管理层、存储层重点开启 `no-unsafe-*` 规则。
4. **团队统一**：在提交前统一通过 ESLint 校验，避免风格和安全规则分裂。
5. **渐进治理**：旧项目可先以 warning 接入，再逐步提升为 error。

## 8. 常见问题及处理建议
1. **外部接口返回值类型不明确**
   - **问题**：接口响应被推断为 `any`，导致触发多条 `no-unsafe-*` 规则。
   - **建议**：为响应结果定义接口，并在进入业务逻辑前完成转换或校验。
2. **公共函数缺少签名**
   - **问题**：导出函数未声明参数或返回值类型。
   - **建议**：为所有模块边界函数补全完整签名，避免隐式推导扩散。
3. **数组遍历写法不规范**
   - **问题**：使用 `for...in` 遍历数组。
   - **建议**：改用 `for...of` 或数组高阶方法，保持语义正确。
4. **历史代码大量使用 `any`**
   - **问题**：一次性整改成本过高。
   - **建议**：按模块逐步替换为接口、泛型或 `unknown`，优先整改核心链路。
