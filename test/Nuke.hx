import nuke.Css;

function main() {
  make(15);
}

function make(height:Int) {
  trace(Css.atoms({
    color: '#ffffff',
    minWidth: '15px',
    minWidth: '15px',
    minWidth: '15px',
    maxWidth: '500px',
    height: height + 'px',
    ':hover': {
      color: 'red',
      width: '500px'
    },
    'li': {
      width: '500px',
      width: '500px',
      width: '500px',
      '&.foo': {
        width: '600px'
      },
      ':hover &.foo': {
        width: '600px'
      },
      'div &.foo': {
        width: '600px'
      },
      '.bar': {
        width: '9000px',
        minWidth: '15px'
      },
      'li': {
        width: '9000px',
        minWidth: '15px'
      },
      ':hover': {
        color: 'red',
        width: '500px'
      },
      '@media (max-width: 500px)': {
        color: 'blue'
      }
    }
  }));
  trace(Css.mediaQuery({
    maxWidth: '200px'
  }, {
    color: 'orange'
  }));
}
