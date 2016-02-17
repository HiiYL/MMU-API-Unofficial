// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require materialize-sprockets
//= require_tree .

$(document).on('page:change', function (){
    $(".button-collapse").sideNav();
    $('#mmls_login_form').on('ajax:send', function(xhr) {
      $("#mmls_login_form").hide();
      $(".loading-spinner").show();
    }).on('ajax:success',function(e, data, status, xhr){
      $(".loading-spinner").hide();
      $(".error-message-box").hide();
      // alert(data);
      $(function() {
        $("#mmls_column").append("<h4>This Week</h4>");
        var outer = $("#mmls_column").append('<ul class="collapsible" data-collapsible="accordion"></ul>').addClass("collapsible popout").find('ul');
        $.each(data, function(i, item) {
          outer_li = $("<li></li>").appendTo(outer);
          outer_li.append('<div class="collapsible-header">' + item.name + '</div>');
          console.log(item.name);
          $.each(item.weeks, function(i, week) {
              if(i == 0) {
                var inner_week = $('<div class="collapsible-body"></div>').appendTo(outer_li);
                var week_container = $('<ul class="collapsible" data-collapsible="accordion"></ul>').appendTo(inner_week);
                console.log(week.title);
                $.each(week.announcements, function(i , announcement) {
                  week_li = $("<li></li>").appendTo(week_container);
                  $('<div class="collapsible-header">' + announcement.title + "</div>").appendTo(week_li);
                  $('<div class="collapsible-body">' + announcement.contents + "</div>").appendTo(week_li);
                })
              }
          })

        })
        $('.collapsible').collapsible({
          accordion : false // A setting that changes the collapsible behavior to expandable instead of the default accordion 
        });
      })
    }).on('ajax:error',function(e, xhr, status, error){
      var jsonValue = jQuery.parseJSON( xhr.responseText);
      $(".error-message-box").show();
      $(".error-message").text(jsonValue.error);
      $(".loading-spinner").hide();
      $("#mmls_login_form").show();

    });
  });