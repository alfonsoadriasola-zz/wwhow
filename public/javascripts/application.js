// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
//-------------------------------------------------------------------- filter
function tableFilter(phrase, _id) {
    var words = phrase.value.toLowerCase().split(" ");
    var table = document.getElementById(_id);
    var rowcontent;
    for (var r = 1; r < table.rows.length; r++) {
        var row = $(table.rows[r].id);
        rowcontent = table.rows[r].innerHTML.replace(/<[^>]+>/g, "");
        for (var i = 0; i < words.length; i++) {
            if (rowcontent.toLowerCase().indexOf(words[i]) >= 0) {
                if (row.className.indexOf("even") >= 0) {
                    $(row.id).className = "show message even";
                }
                else {
                    $(table.rows[r].id).className = "show message odd";
                }
            }
            else {
                if ($(table.rows[r].id).className.indexOf("even") >= 0)
                {
                    $(table.rows[r].id).className = "hide message even";
                }
                else
                {
                    $(table.rows[r].id).className = "hide message odd";
                }
            }
        }
    }
}

//--------------------------------------------------------------------toooltips
function hide_tooltip() {
    var tip = $("tooltipper");
    tip.update("");
    tip.hide();
}

function show_tooltip(event, txt) {
    var tip = $("tooltipper");
    tip.setStyle({left:event.clientX + 20});
    tip.setStyle({top:event.clientY + 30});
    tip.update(txt);
    tip.show();
}

function submitAll() {
    forms = $$('form');
    forms.invoke("submit");
}

function submitByTag(tag) {
    $('blog_entry_category_list').setValue(tag);
    $('searchTable').up('form').submit();
}

function submitByFavorites(){
    $('searchTable').up('form').submit();    
}

function submitByUser(author_id) {
    $('blog_entry_author_id').setValue(author_id);
    $('searchTable').up('form').submit();
}

function slidersOn() {
    new Effect.BlindDown('sliders');
    $('slidersOff').show();
    $('slidersOn').hide();
    $('blog_entry_sliders').setValue(true);
    if ($('welcome')) {
        new Effect.Shrink('welcome');
        new Effect.Appear('tipsy-pen');
    }
}

function slidersOff() {
    new Effect.BlindUp('sliders');
    $('slidersOff').hide();
    $('slidersOn').show();
    $('blog_entry_sliders').setValue(false);
    if ($('welcome')) {
        new Effect.BlindDown('welcome');
        $('tipsy-pen').hide();
    }
}

function mapOn() {
    $('mapframe').show();
    $('map').show();
    $('mapOn').hide();
    $('mapOff').show();
    $('blog_entry_map').setValue(true);
}

function mapOff() {
    new Effect.BlindUp('mapframe');
    $('mapOff').hide();
    $('mapOn').show();
    $('blog_entry_map').setValue(false);
}

function showMapIcon(mapIndex){
    if(map == null){startMap();}
    mapOn();
    var iconcount = map.Hb.length
    var theMapIcon=map.Hb[iconcount - mapIndex].ja;
    if(map.getZoom() < 14) map.setZoom(14);  
    map.panTo(theMapIcon);  
}



function set_show_friends_only(_value) {
    if (_value)
        $('user_show_friends_only').setValue(1);
    else
        $('user_show_friends_only').setValue(0);

    submitByFavorites();    
}

function set_show_unmapped  (_value) {
    if (_value)
        $('user_show_unmapped').setValue(1);
    else
        $('user_show_unmapped').setValue(0);

    submitByFavorites();
}

function toggle_hide_blocked_users(_value) {
    $('user_hide_blocked_users').setValue(_value);
}

function submitenter(myfield, e)
{
    var keycode;
    if (window.event) keycode = window.event.keyCode;
    else if (e) keycode = e.which;
    else return true;
    if (keycode == 13)
    {
        myfield.form.submit();
        return false;
    }
    else
        return true;
}