var warnMyAccountLeavingUnsavedMessage;
function warnMyAccountLeavingUnsaved(message) {
  warnMyAccountLeavingUnsavedMessage = message;

  $('form').submit(function(){
    $('input,select').removeData('changed');
  });
  $('input,select').change(function(){
    $(this).data('changed', 'changed');
  });
  window.onbeforeunload = function(){
    var warn = false;
    $('input,select').blur().each(function(){
      if ($(this).data('changed')) {
        warn = true;
      }
    });
    if (warn) {return warnMyAccountLeavingUnsavedMessage;}
  };
}
