import js.Browser;

using Nuke;

class Test {
  static var width = 150.px();
  static final fontColor = Theme.property(app.font.color, 'orange');
  static final bgColor = Theme.property('bg-color');

  static function main() {
    Theme.global({
      bg: {
        color: 'green'
      }
    });

    Css.global({
      body: {
        padding: 'none',
        backgroundColor: 'blue',
        font: list('"Helvetica"', 'sans-serif')
      },
      div: {
        padding: '10px'
      }
    });

    var boxStyle = Css.atoms({
      color: theme(font.color, fontColor),
      fontFamily: theme(font.family),
      backgroundColor: theme(bg.color),
      height: 130.px() + 50.pct(),
      '@media screen and (min-width: 50px)': {
        width: 20.px()
      }
    }).with(Theme.define({
      bg: {
        color: 'purple'
      },
      font: {
        color: 'grey',
        family: list('"Helvetica"', 'sans-serif')
      }
    }));
    
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
