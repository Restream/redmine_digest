$(document).ready(function() {

  var toggleProjectList = function() {
    var selectedVal = $("#digest_rule_project_selector").val();
    if ($.inArray(selectedVal, ["selected", "not_selected", "member_not_selected"]) < 0) {
      $("#digest-rule-projects").hide();
    } else {
      $("#digest-rule-projects").show();
    }
  };

  $("#digest_rule_project_selector").select2({
    width: "40%",
    allowClear: false
  }).on("change", toggleProjectList);

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

  toggleProjectList();
});
