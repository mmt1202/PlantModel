import mediaquery from '@ohos.mediaquery'

export enum BreakpointType {
  XS = 'xs',
  SM = 'sm',
  MD = 'md',
  LG = 'lg',
  XL = 'xl'
}

export class BreakpointManager {
  private static instance: BreakpointManager
  private tabletListener: mediaquery.MediaQueryListener | null = null
  private largeScreenListener: mediaquery.MediaQueryListener | null = null
  private currentBreakpoint: BreakpointType = BreakpointType.SM
  private onChangeCallback: ((bp: BreakpointType) => void) | null = null

  static getInstance(): BreakpointManager {
    if (!BreakpointManager.instance) {
      BreakpointManager.instance = new BreakpointManager()
    }
    return BreakpointManager.instance
  }

  init(onChange?: (bp: BreakpointType) => void): void {
    this.onChangeCallback = onChange || null

    this.tabletListener = mediaquery.matchMediaSync('(min-width: 840vp)')
    this.tabletListener.on('change', (result: mediaquery.MediaQueryResult) => {
      this.updateBreakpoint()
    })

    this.largeScreenListener = mediaquery.matchMediaSync('(min-width: 1200vp)')
    this.largeScreenListener.on('change', (result: mediaquery.MediaQueryResult) => {
      this.updateBreakpoint()
    })

    this.updateBreakpoint()
  }

  private updateBreakpoint(): void {
    const isLargeScreen = this.largeScreenListener?.matches ?? false
    const isTablet = this.tabletListener?.matches ?? false

    let newBreakpoint: BreakpointType
    if (isLargeScreen) {
      newBreakpoint = BreakpointType.XL
    } else if (isTablet) {
      newBreakpoint = BreakpointType.LG
    } else {
      newBreakpoint = BreakpointType.SM
    }

    if (this.currentBreakpoint !== newBreakpoint) {
      this.currentBreakpoint = newBreakpoint
      if (this.onChangeCallback) {
        this.onChangeCallback(this.currentBreakpoint)
      }
    }
  }

  getCurrentBreakpoint(): BreakpointType {
    return this.currentBreakpoint
  }

  isTabletOrFoldable(): boolean {
    return this.currentBreakpoint === BreakpointType.LG ||
           this.currentBreakpoint === BreakpointType.XL
  }

  isLargeScreen(): boolean {
    return this.currentBreakpoint === BreakpointType.XL
  }

  getLeftPaneWidth(): string {
    if (this.currentBreakpoint === BreakpointType.XL) {
      return '30%'
    }
    return '35%'
  }

  getRightPaneWidth(): string {
    if (this.currentBreakpoint === BreakpointType.XL) {
      return '70%'
    }
    return '65%'
  }

  getQuickActionColumns(): string {
    if (this.currentBreakpoint === BreakpointType.XL) {
      return '1fr 1fr 1fr 1fr'
    }
    if (this.currentBreakpoint === BreakpointType.LG) {
      return '1fr 1fr 1fr'
    }
    return '1fr 1fr'
  }

  destroy(): void {
    if (this.tabletListener) {
      this.tabletListener.off('change')
      this.tabletListener = null
    }
    if (this.largeScreenListener) {
      this.largeScreenListener.off('change')
      this.largeScreenListener = null
    }
    this.onChangeCallback = null
  }
}
