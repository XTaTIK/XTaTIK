jQuery(function ($) {
    fix_nav_padding_top();
    $( window ).resize(function() { fix_nav_padding_top(); });

    setup_feedback_button();
});

function fix_nav_padding_top() {
    $('body').css('padding-top',
        ($('.navbar-fixed-top').outerHeight() + 19) + 'px'
    );
}

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