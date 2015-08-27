jQuery(function ($) {
    $.fn.sameHeight = function() {
        var max = 0;
        $(this).each(function(){
            var h = $(this).outerHeight();
            if ( h > max ) { max = h }
        });

        $(this).css('min-height', max + 'px')
    }

    fix_nav_padding_top();
    $( window ).resize(function() { fix_nav_padding_top(); });

    setup_product_list();
    setup_feedback_button();
    setup_index_shoutout();
});

function setup_product_list() {
    if ( ! $('#product_list').length ) { return; }

    var thumb = $('#product_list .thumbnail');
    thumb.sameHeight();
    thumb.css({'line-height': thumb.eq(0).outerHeight() + 'px'});

    $('#product_list a[href^="/product/"]:not(.thumbnail)').sameHeight();
}

function setup_index_shoutout() {
    if ( ! $('#index_shoutout').length ) { return; }

    var hot = $('.hot_products_container'),
        shout = $('#index_shoutout'),
        logo  = shout.find('img'),
        tag   = shout.find('.market_tag');

    hot.css({ opacity: 0 }).find('li').css({ opacity: 0 });
    shout.css({ opacity: 1 });

    setTimeout(function(){
        var end_height = logo.outerHeight();
        if ( end_height > 250 ) { end_height = 250 }

        logo.animate({
            height: end_height
        }, 500, function(){
            tag.css({transform: 'scale(1.2)'});
            setTimeout(function(){
                shout.css({ opacity: 0 });
                logo.css({
                    height: 'auto',
                    'max-height': end_height
                });
                shout.find('.col-sm-12').removeClass('col-sm-12')
                    .addClass('col-sm-6');

                tag.css({
                    'font-size': '200%',
                    transition: 'transform 0s',
                    transform: 'scale(1)'
                });

                // See if we have room to scale up market tag
                if ( tag.outerHeight() < (end_height/2) ) {
                    tag.css({'font-size': '230%'})
                }

                // Center market tag vertically
                tag.css( 'padding-top',
                    ( end_height - tag.outerHeight() )/2
                );

                $('#index_shoutout').animate({opacity: 1}, 500, function(){
                    hot.animate({opacity: 1}, 300, function() {
                        $(this).find('li').each(function(i, el) {
                            setTimeout( function() {
                                $(el).animate({opacity: 1});
                            }, 200*i );
                        });
                    });
                });
            }, 3000);
        });
    }, 700);
}

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