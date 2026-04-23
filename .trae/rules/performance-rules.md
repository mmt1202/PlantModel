# ArkTS/ArkUI 性能优化通用规则规范

## 1. 推荐规则集
### 1.1 `@performance/recommended`
- **规则说明**：启用官方推荐的性能规则集，涵盖了高频函数、组件复用、状态管理更新等常见的性能卡点检查。
- **适用建议**：建议所有应用项目默认开启，在代码编写和 CI/CD 阶段及时拦截性能劣化风险。

## 2. 组件与渲染性能优化
### 2.1 `@performance/avoid-overusing-custom-component-check`
- **规则说明**：当在应用中使用自定义组件时，可以优先使用 `@Builder` 函数代替自定义组件。
- **最佳实践**：`@Builder` 函数不会在后端 FrameNode 节点树上创建一个新的树节点，有助于缩短页面的加载和渲染时长。

### 2.2 `@performance/hp-arkui-replace-nested-reusable-component-by-builder`
- **规则说明**：建议使用 `@Builder` 替代嵌套的自定义组件，以减小组件树层级和渲染开销。

### 2.3 `@performance/hp-arkui-use-reusable-component`
- **规则说明**：建议复杂组件的定义尽量使用组件复用（如 `@Reusable`），以降低重复创建组件的开销。

### 2.4 `@performance/hp-arkui-suggest-reuseid-for-if-else-reusable-component`
- **规则说明**：建议使用 `reuseId` 标记不同结构的组件构成，提升复用命中率与效率。

### 2.5 `@performance/hp-arkui-no-func-as-arg-for-reusable-component`
- **规则说明**：避免使用函数作为复用的自定义组件创建时的入参，以防止每次渲染都生成新函数导致复用失效或冗余更新。

## 3. 列表与循环渲染优化
### 3.1 `@performance/foreach-args-check`
- **规则说明**：建议在 `ForEach` 参数中设置 `keyGenerator`。
- **最佳实践**：提供稳定且唯一的 key 生成规则，避免数组更新时发生全量 UI 重绘。

### 3.2 `@performance/hp-arkui-no-stringify-in-lazyforeach-key-generator`
- **规则说明**：在使用 `LazyForEach` 进行组件复用的 key 生成器函数里，不要使用 `JSON.stringify`，以免带来高昂的序列化性能开销。

### 3.3 `@performance/hp-arkui-set-cache-count-for-lazyforeach-grid`
- **规则说明**：建议在 `Grid` 下使用 `LazyForEach` 时设置合理的 `cacheCount`，提前加载视口外的少量节点，提升滚动流畅度。

### 3.4 `@performance/waterflow-data-preload-check`
- **规则说明**：建议对 `WaterFlow` 子组件进行数据预加载，优化瀑布流场景下的滑动体验。

## 4. 状态管理与更新优化
### 4.1 `@performance/hp-arkui-no-state-var-access-in-loop`
- **规则说明**：避免在 `for`、`while` 等循环逻辑中频繁读取状态变量。
- **最佳实践**：在循环外将状态变量读取到局部变量中进行操作。

### 4.2 `@performance/hp-arkui-use-local-var-to-replace-state-var`
- **规则说明**：建议在复杂计算逻辑中使用临时变量替换状态变量，计算完成后再统一赋值，避免触发多次无用的 UI 渲染或依赖收集。

### 4.3 `@performance/hp-arkui-use-object-link-to-replace-prop`
- **规则说明**：建议使用 `@ObjectLink` 代替 `@Prop`，减少不必要的深拷贝带来的内存与时间开销。

### 4.4 `@performance/hp-arkui-avoid-update-auto-state-var-in-aboutToReuse`
- **规则说明**：避免在 `aboutToReuse` 生命周期中对自动更新值的状态变量进行更新，以防触发非预期的冗余渲染。

## 5. 动画与图形优化
### 5.1 `@performance/hp-arkui-combine-same-arg-animateto`
- **规则说明**：建议动画参数相同时，将多个状态更新合并到同一个 `animateTo` 中执行。

### 5.2 `@performance/update-state-var-between-animatetos-check`
- **规则说明**：不建议在两次 `animateTo` 之间进行状态变量更新，这会导致执行下一个 `animateTo` 之前产生脏节点，造成冗余更新。

### 5.3 `@performance/hp-arkui-use-scale-to-replace-attr-animateto`
- **规则说明**：建议组件布局改动时使用图形变换属性动画（如 scale、translate 等），而非直接修改 width/height 等触发布局重排的属性。

### 5.4 `@performance/hp-arkui-use-transition-to-replace-animateto`
- **规则说明**：建议组件转场动画使用 `transition` 而非 `animateTo` 模拟。

### 5.5 `@performance/monitor-invisible-area-in-image-animation`
- **规则说明**：使用 `ImageAnimation` 实现帧动画时，建议显式调用 `monitorInvisibleArea` 接口，使组件不可见时自动停止播放。

### 5.6 `@performance/hp-arkui-suggest-use-effectkit-blur`
- **规则说明**：建议使用 `effectKit.createEffect` 实现模糊效果，替代低效的模糊实现方式。

### 5.7 `@performance/gif-hardware-decoding-check`
- **规则说明**：在使用 `@ohos/gif-drawable` 库解码 gif 图片时，建议开启硬解码，提升加载与播放性能。

## 6. 模块加载与导入优化
### 6.1 `@performance/hp-arkui-load-on-demand`
- **规则说明**：建议使用按需加载（动态 `import()`），缩短应用首屏启动时间。

### 6.2 `@performance/no-use-any-import`
- **规则说明**：建议按需引用使用到的变量代替 `import * as xxx`，以减少 `.ets` 文件的执行耗时和文件中所有 export 变量的初始化过程。

### 6.3 `@performance/hp-arkts-no-use-any-export-current` 与 `@performance/hp-arkts-no-use-any-export-other`
- **规则说明**：避免使用 `export *` 导出当前模块或其他模块中定义的类型和数据，防止无用代码被打入产物或增加模块解析开销。

## 7. 内存管理与高频逻辑优化
### 7.1 `@performance/bad-deep-clone-check`
- **规则说明**：避免使用不合理的深拷贝，如 `JSON.parse(JSON.stringify(foo))` 和 `_.cloneDeep(foo)`。

### 7.2 `@performance/reuse-date-instances-check`
- **规则说明**：检测在循环或调用频繁的方法中重复创建 `Date` 对象，建议重用现有实例或使用时间戳（如 `Date.now()`）进行计算。

### 7.3 `@performance/high-frequency-log-check`
- **规则说明**：不建议在高频函数（如 `onScroll`、`onTouch`、`onAreaChange` 等）中使用 `Hilog` 打印日志，以免引发性能瓶颈。

### 7.4 `@performance/datashare-query-unrelease-check`
- **规则说明**：建议使用 `DataShareHelper` 的 query 接口查询数据得到结果后及时关闭，避免造成内存泄露。

## 8. 系统接口与原生能力替代
### 8.1 `@performance/crypto-replacement-check`
- **规则说明**：建议使用系统原生接口（`@ohos.security.cryptoFramework`）替代三方库 `@ohos/crypto-js` 所提供的大部分接口，以获取更好的性能与安全性。

### 8.2 `@performance/hp-ffrt-no-use-std`
- **规则说明**：禁止在 FFRT worker 中使用 `std::xxx` 等同步接口，防止阻塞 worker 线程池。

### 8.3 `@performance/hp-arkui-use-onAnimationStart-for-swiper-preload`
- **规则说明**：建议 `Swiper` 预加载机制搭配 `onAnimationStart` 接口回调使用，平滑预加载过程。

### 8.4 `@performance/hp-arkui-suggest-cache-avplayer`
- **规则说明**：建议缓存 `AVPlayer` 实例，以减少视频起播时延。

### 8.5 `@performance/hp-arkui-use-grid-layout-options`
- **规则说明**：建议在指定位置时使用 `GridLayoutOptions` 提升 `Grid` 性能。

## 9. 启动与渲染策略
### 9.1 `@performance/start-window-icon-check`
- **规则说明**：启动页图标分辨率建议不超过 256 * 256，防止拖慢启动速度。

### 9.2 `@performance/web-on-active-check`
- **规则说明**：使用了 Web 预渲染技术的应用，建议在预渲染完成后（`onFirstMeaningfulPaint`），调用停止渲染接口（`onInactive`）。

### 9.3 `@performance/no-high-loaded-frame-rate-range`
- **规则说明**：不允许锁定最高帧率运行，应根据实际业务需求动态调整帧率，兼顾性能与功耗。