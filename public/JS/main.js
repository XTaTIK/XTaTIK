jQuery(function ($) {
    $('body').css('padding-top',
        ($('.navbar-fixed-top').outerHeight() + 19) + 'px'
    );

    setup_feedback_button();
});

function setup_feedback_button() {
    if ( $('form[action="/feedback"]').length )  {
        $('#feedback_b').remove();
        return;
    }

    var width = $('#feedback_b span').outerWidth();
    $('#feedback_b span')
        .css({ position: 'static', width: 0, 'padding-left': 0});

    $('#feedback_b')
        .hover(function() {
            $(this).find('span')
                .stop(true, false)
                .animate({
                    width: width + 'px',
                    'padding-left': '10px'
                }, 400);
        }, function() {
            $(this).find('span')
                .stop(true, false)
                .animate({
                    width: 0,
                    'padding-left': 0
                }, 400);
        });
}