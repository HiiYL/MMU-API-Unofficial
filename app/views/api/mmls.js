$("#mmls_login_form").hide();
$("#mmls_column").append('<ul class="collapsible popout">');
<% @subjects.each do |subject| %>
	$("#mmls_column").append('<div class="collapsible-header"><%= escape_javascript( subject.name ) %></div><%= subject.weeks.each do |week| %><div class="collapsible-body"><%= week.title %></div><%end%>
		  ');
<% end %>
$("#mmls_column").append("</ul");