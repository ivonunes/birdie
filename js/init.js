// to animate the collapse caret
$(document).ready(function(){   
    $("a.collapse-link").click(function(){
        $("i").toggleClass("active");
    });
});

// to toggle show/hide collapse caret
$(document).ready(function(){   
    $("a.collapse-link").click(function(){
        $("span").toggleClass("hidden");
    });
});