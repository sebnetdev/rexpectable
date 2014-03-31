//Waiting for DOM completely loaded
$(document).ready(function() {
    console.log('DOM is ready');
    openOnClick();
    hideTableLineOnClick("hidden");
    
});


var openOnClick = function(){
    //on div.cellContent click
    $(".cellContent").on("click", function(evt) {

        //get the current 
        var currentTarget = $(evt.currentTarget);

        //is the div overflow ?
        if ($(evt.currentTarget)[0].scrollHeight > $(evt.currentTarget)[0].clientHeight) {

            if (currentTarget.hasClass('cellContent')) {

                $(evt.currentTarget).parent().parent().find(".cellContent").addClass("cellContentOpened")
                $(evt.currentTarget).parent().parent().find(".cellContent").removeClass("cellContent")
            } else {
                $(evt.currentTarget).parent().parent().find(".cellContentOpened").addClass("cellContent");
                $(evt.currentTarget).parent().parent().find(".cellContent").removeClass("cellContentOpened")
            }
        } else {
            $(evt.currentTarget).parent().parent().find(".cellContentOpened").addClass("cellContent");
            $(evt.currentTarget).parent().parent().find(".cellContent").removeClass("cellContentOpened")
        }

    });
}

/**
 * Hide the table line (tr) with the given classname 
 * when clicking on the magic button
 * @param  String classname
 */
var hideTableLineOnClick = function(classname){

    $('#hideTableLine').on('click',function(){
        $("."+classname).toggle();
    });
}
