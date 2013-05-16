$(document).ready(function() {


  $("#digest_rule_recurrent").select2({
    width: "20%",
    allowClear: false
  });

  $("#digest_rule_project_selector").select2({
    width: "40%",
    allowClear: false    
  }).on("change", function(e) {
    if ($.inArray(e.val, ["selected", "not_selected"]) < 0) {
      $("#digest-rule-projects").hide();
    } else {
      $("#digest-rule-projects").show();
    }
  }).trigger("change");


  $("#digest_rule_raw_project_ids").select2({
    width: "40%",
    multiple: true,
    data: $("#digest_rule_raw_project_ids").data("options"),
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
