// Text line width
const TEXT_WIDTH: number = 350;
// Number of lines to show when collapsed
const COLLAPSE_LINES: number = 2;
const ELLIPSIS: string = '...';
const EXPAND_STR: string = 'Expand';
const COLLAPSE_STR: string = 'Collapse';
const FULL_TEXT: string =
  'HarmonyOS provides a UI development framework called the ArkUI Framework. The ArkUI Framework provides developers with ' +
    'essential capabilities for application UI development, such as multiple components, layout calculations, animation capabilities, UI interaction, drawing, etc.\n' +
    'The ArkUI Framework offers two development paradigms for developers with different purposes and technical backgrounds: ' +
    'the Declarative Development Paradigm based on ArkTS (referred to as the "Declarative Development Paradigm") ' +
    'and the JS-compatible Web Development Paradigm (referred to as the "Web Development Paradigm"). Here is a simple comparison of these two development paradigms.'


@ComponentV2
export  struct TextCollapseTest {
  @Local title: string = FULL_TEXT;
  @Local suffixStr: string = '';
  private expanded: boolean = true;
  private needProcess: boolean = true;

  aboutToAppear(): void {
    this.process();
  }

  process(): void {
    if (this.expanded) {
      this.collapseText();
    } else {
      this.expandText();
    }
  }

  // Expand text
  expandText(): void {
    if (this.needProcess) {
      this.suffixStr = COLLAPSE_STR;
      this.expanded = true;
      this.title = FULL_TEXT;
    }
  }

  // Collapse text
  collapseText(): void {
    if (!this.needProcess) {
      this.suffixStr = '';
      return;
    }
    // Size of expanded text
    let expandSize: SizeOptions = this.getUIContext().getMeasureUtils().measureTextSize({
      textContent: FULL_TEXT,
      constraintWidth: TEXT_WIDTH,
      fontSize: 30
    });

    // Size of text to be collapsed
    let collapseSize: SizeOptions = this.getUIContext().getMeasureUtils().measureTextSize({
      textContent: FULL_TEXT,
      constraintWidth: TEXT_WIDTH,
      fontSize: 30,
      maxLines: COLLAPSE_LINES
    });

    // No processing needed when collapsed and expanded text heights are equal
    if (!expandSize || !collapseSize || (expandSize.height as number) == (collapseSize.height as number)) {
      this.needProcess = false;
      return;
    }

    let clipTitle: string = FULL_TEXT;
    this.suffixStr = EXPAND_STR;
    // Use binary search to find string length that fits exactly two lines
    let leftCursor: number = 0;
    let rightCursor: number = this.title.length;
    let cursor: number = Math.floor(rightCursor / 2);
    let tempTitle: string = '';
    // Binary search to find the maximum text length fitting exactly two lines
    while (true) {
      tempTitle = this.title.substring(0, cursor) + ELLIPSIS + EXPAND_STR;
      const currentLinesTextSize: SizeOptions = this.getUIContext().getMeasureUtils().measureTextSize({
        textContent: tempTitle,
        fontSize: 30,
        wordBreak: WordBreak.BREAK_ALL,
        constraintWidth: TEXT_WIDTH
      });

      if ((currentLinesTextSize.height as number) > (collapseSize.height as number)) {
        // Current text exceeds two lines, continue searching left
        rightCursor = cursor;
        cursor = leftCursor + Math.floor((cursor - leftCursor) / 2);
      } else {
        // Current text less than two lines, might be ok but still need to search right
        leftCursor = cursor;
        cursor += Math.floor((rightCursor - cursor) / 2);
      }
      if (Math.abs(rightCursor - leftCursor) <= 1) {
        // Pointers almost overlap, meaning we found the position
        break;
      }
    }
    clipTitle = this.title.substring(0, cursor - 1);
    this.title = clipTitle + ELLIPSIS;
    this.expanded = false;
  }

  build() {
    Row() {
      Column() {
        Text() {
          Span(this.title)
          if (this.needProcess) {
            Span(this.suffixStr)
              .fontColor(Color.Orange)
              .onClick(() => {
                this.process();
              })
          }
        }
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width(TEXT_WIDTH)
      }
      .width('100%')
    }
    .height('100%')
  }
}