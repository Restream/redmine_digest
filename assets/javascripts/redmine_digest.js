$(document).ready(function() {

  $('#digest_rule_projects').select2({
    width: '40%',
    multiple: true,
    data: $('#digest_rule_projects').data('options'),
    matcher: function(term, text, option) {
      // ignore groups
      if (option.children == undefined) {
        return text.toUpperCase().indexOf(term.toUpperCase()) >=0;
      } else {
        return false;
      }
    }
  });

});
