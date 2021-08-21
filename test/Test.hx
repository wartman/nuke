import js.Browser;

using Nuke;

class Test {
  static var width = 150.px();

  static function main() {
    // Css.injectGlobalCss({
    //   body: {
    //     padding: 'none',
    //     backgroundColor: 'blue'
    //   },
    //   div: {
    //     padding: '10px'
    //   }
    // });

    // Instead of injectGlobalCss, we're trying this:
    Browser.document.body.className = Css.atoms({
      padding: 'none',
      backgroundColor: 'blue',
      div: {
        padding: 10.px(),
        margin: 0
      }
    });

    var boxStyle = Css.atoms({
      color: 'blue',
      backgroundColor: 'green',
      height: 130.px() + 50.pct(),
      '@media screen and (min-width: 50px)': {
        width: 20.px()
      }
    });
    
    var el = Browser.document.createDivElement();
    Browser.document.body.appendChild(el);
    el.className = Css.atoms({
      width: width,
      height: '130px',
      backgroundColor: '#cccccc',
      ':hover': {
        backgroundColor: '#555555',
      },
      p: {
        padding: [ '50px', '20px' ],
        color: 'red'
      }
    });
    el.innerHTML = '<p>Foo!</p>';
    el.addEventListener('click', e -> {
      el.className = Css.atoms({
        width: '150px',
        height: '130px',
        backgroundColor: '#bbbbbb'
      }).with(
        Css.mediaQuery({ 
          minWidth: '900px', 
          type: 'screen'
        }, { width: '80px' })
      );
    });

    var el2 = Browser.document.createDivElement();
    el2.className = boxStyle;
    el2.innerHTML = '<p>Foo!</p>';
    Browser.document.body.appendChild(el2);
  }
}
