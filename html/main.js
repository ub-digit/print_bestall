$(document).ready(function() {
  $('#enhetSelect').click(function(event) {	
    $( "#enhetDiv" ).dialog("close");
    $( "#dateSelectorDiv" ).dialog({
      modal: true,
      title: "Välj tidsintervall",
      width: 600
    });
    showOnly('dateSelectorDiv');
  });
  /* --------------------------------------------------------- */
  $('#datesBtn').click(function(event) {
    event.preventDefault();
    $('#fileSelect').load('/cgi-bin/reprint.cgi', {
      action:'calculate',
      enhet:$('#enhetSelect').val(),
      fromDate:$('#fromDate').val().replace(/\D/g,''),
      toDate:$('#toDate').val().replace(/\D/g,''),
      function(){ $( "#dateSelectorDiv" ).dialog("close"); }
    });
    $('#resultDiv').load('/cgi-bin/reprint.cgi?action=calculate&calc=true&enhet='+$('#enhetSelect').val()+'&fromDate=' + $('#fromDate').val().replace(/\D/g,'') + '&toDate=' + $('#toDate').val().replace(/\D/g,''), function() {
      var resultDivText = $('#resultDiv').text();
      if (resultDivText == 'Inga filer motsvarar sökningen.') { 
        $( "#finalDiv" ).dialog({
          modal: true,
          title: 'Inget resultat'
        });
        $( "#finalResultDiv" ).html(resultDivText);
        showOnly('finalDiv');
      } else {
        $( "#filesPreviewDiv" ).dialog({
          modal: true,
          title: "Bekräfta"
        });
        showOnly('filesPreviewDiv');
      }
    });
  });
  /* --------------------------------------------------------- */
  $('#reprintBtn').click(function(event) {
    event.preventDefault();
    var filesSelected = $('#fileSelect option').size();
    if ( filesSelected > 200 ) {
      var res = confirm("Är du medveten om att du står i begrepp att skriva ut " + filesSelected + " beställningar?");
      if ( !res ) {
        location.reload(true);
        return;
      }
    }
    if ( filesSelected > 0) {
      for (var i=0; i<fileSelect.options.length; i++) {
        fileSelect.options[i].selected = true;
      }
      $('#finalResultDiv').load('/cgi-bin/reprint.cgi', {
        action:'send',
        fileSelect:$('#fileSelect').serialize()
      });
      $( "#filesPreviewDiv" ).dialog("close");
      $( "#finalDiv" ).dialog({
        modal: true,
        title: "Färdigt"
      });
    } else {
      $('#resultDiv').load('/cgi-bin/reprint.cgi?action=error');
    }
    showOnly('finalDiv');
  });
  /* --------------------------------------------------------- */
  $('.cancelBtn').click(function(event) {
    event.preventDefault();
    location.reload(true);
  });
  /* --------------------------------------------------------- */
  function showOnly(divIdToShow) {
    $('#enhetDiv').hide();
    $('#filesPreviewDiv').hide();
    $('#finalDiv').hide();
    $('#dateSelectorDiv').hide();
    $('#' + divIdToShow).show();
  }
});
