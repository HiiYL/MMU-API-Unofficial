class ApiController < ApplicationController
  def timetable
  	agent = Mechanize.new
    agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    page = agent.get("https://cms.mmu.edu.my")
    form = page.form
    form.userid = params[:student_id] ||= ENV['STUDENT_ID']
    form.pwd = params[:password] ||= ENV['CAMSYS_PASSWORD']
    page = agent.submit(form)
    if page.parser.xpath('//*[@id="login_error"]').empty?
      print "HELLO THERE!!@!@#{}"
      page = agent.get("https://cms.mmu.edu.my/psc/csprd/EMPLOYEE/HRMS/c/SA_LEARNER_SERVICES.SSR_SSENRL_LIST.GBL?PORTALPARAM_PTCNAV=HC_SSR_SSENRL_LIST&amp;EOPP.SCNode=HRMS&amp;EOPP.SCPortal=EMPLOYEE&amp;EOPP.SCName=CO_EMPLOYEE_SELF_SERVICE&amp;EOPP.SCLabel=Self%20Service&amp;EOPP.SCPTfname=CO_EMPLOYEE_SELF_SERVICE&amp;FolderPath=PORTAL_ROOT_OBJECT.CO_EMPLOYEE_SELF_SERVICE.HCCC_ENROLLMENT.HC_SSR_SSENRL_LIST&amp;IsFolder=false&amp;PortalActualURL=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2fEMPLOYEE%2fHRMS%2fc%2fSA_LEARNER_SERVICES.SSR_SSENRL_LIST.GBL&amp;PortalContentURL=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2fEMPLOYEE%2fHRMS%2fc%2fSA_LEARNER_SERVICES.SSR_SSENRL_LIST.GBL&amp;PortalContentProvider=HRMS&amp;PortalCRefLabel=My%20Class%20Schedule&amp;PortalRegistryName=EMPLOYEE&amp;PortalServletURI=https%3a%2f%2fcms.mmu.edu.my%2fpsp%2fcsprd%2f&amp;PortalURI=https%3a%2f%2fcms.mmu.edu.my%2fpsc%2fcsprd%2f&amp;PortalHostNode=HRMS&amp;NoCrumbs=yes&amp;PortalKeyStruct=yes")
      table = page.parser.xpath('//*[@id="ACE_STDNT_ENRL_SSV2$0"]')
      timetable = Timetable.new
      a = 2
      while !table.xpath("tr[#{a}]").empty? do
        filter = table.xpath("tr[#{a}]/td[2]/div/table")
        subject = timetable.subjects.build
        subject.name = filter.xpath('tr[1]').text
        status_temp = filter.xpath("tr[2]/td[1]/table/tr[2]").text.split("\n")
        status_temp.delete("")
        subject.status = status_temp[4]
        i = 2
        subject_class = subject.subject_classes.build
        holder = filter.xpath('tr[2]/td[1]/table/tr[3]/td/div/table')
        while !holder.xpath("tr[#{i}]").empty? do
          temp = holder.xpath("tr[#{i}]")
          test = temp.xpath('td[1]').text.split("\n")
          unless test.join.blank?
             unless subject_class.class_number.nil?
              print "HELLLLLLLLLLLOOOOO"
               subject_class = subject.subject_classes.build
             end
            subject_class.class_number = temp.xpath('td[1]').text.delete("\n")
            subject_class.section = temp.xpath('td[2]').text.delete("\n")
            subject_class.component = temp.xpath('td[3]').text.delete("\n")
          end
          timeslot = subject_class.timeslots.build
          timeslot.day = temp.xpath('td[4]').text.delete("\n").split(" ")[0]
          timeslot.start_time = temp.xpath('td[4]').text.delete("\n").slice!(3,999).split(" - ")[0]
          timeslot.end_time = temp.xpath('td[4]').text.delete("\n").slice!(3,999).split(" - ")[1]
          timeslot.venue = temp.xpath('td[5]').text.delete("\n")
          print "WOW THIS IS GOING BIG"
          print i
          i = i + 1
        end
        a = a + 2
      end
      render :json => JSON.pretty_generate(timetable.as_json(
        :include => { :subjects => {
         :include => { :subject_classes => {
          :include => :timeslots, :except => [:id]} }, :except => [:id,:subject_class_id] }},
           :except => [:id, :timetable_id]))
    else
      render json: { error: "Incorrect username or password", status: 500}
    end
  end
  private
   def timetable_params
      timetable_params.allow("student_id", "password")
   end
end
