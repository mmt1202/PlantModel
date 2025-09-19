@ComponentV2
export struct  ShowTipBanner{

  @Local bannerMsg:string = ''
  @Local bannerType: string = ''

  public  showBanner(text: string, type: 'ok' | 'warn' | 'info' = 'info'): void {
    this.bannerMsg = text;
    this.bannerType = type
    setTimeout(() => {
      animateTo({ duration: 180, curve: Curve.EaseInOut }, () => {
        this.bannerMsg = ''
      })
    }, 2800)
  }
  build() {
    if (this.bannerMsg.length > 0){
      Row() {
        if (this.bannerType === 'ok') {
          Text('✓').fontSize(14).fontWeight(FontWeight.Medium).fontColor(0xFF2E7D32).margin({ right: 8 })
        }
        if (this.bannerType === 'warn') {
          Text('!').fontSize(14).fontWeight(FontWeight.Medium).fontColor(0xFFEF6C00).margin({ right: 8 })
        }
        if (this.bannerType === 'info') {
          Text('i').fontSize(14).fontWeight(FontWeight.Medium).fontColor(0xFF1565C0).margin({ right: 8 })
        }
        Text(this.bannerMsg).fontSize(13).fontColor(this.bannerType === 'ok' ? 0xFF2E7D32 : (this.bannerType === 'warn' ? 0xFFEF6C00 : 0xFF1565C0))
      }
      .padding({
        left: 14,
        right: 14,
        top: 10,
        bottom: 10
      })
      .layoutWeight(100)
      .zIndex(1000)
      .borderRadius(16)
      .backgroundColor(this.bannerType === 'ok' ? 0xFFE8F5E9 : (this.bannerType === 'warn' ? 0xFFFFF3E0 : 0xFFE3F2FD))
      .position({ x: 12, y: 70 })
      .shadow({
        radius: 12,
        color: 0x18000000,
        offsetX: 0,
        offsetY: 4
      })
      .animation({ duration: 220, curve: Curve.EaseInOut })
    }

  }
}