# MMU-API-Unofficial
Endpoints for MMU sites through web scraping

### Endpoints
` /login_camsys_v2 `
```
{
  "subjects_attendance": [
    {
      "Class Nbr": "2697",
      "Subject Area": "T",
      "Subject/Catalogue#": "CP2201",
      "Course Component": "Lecture",
      "Course Description": "OOAD",
      "Lecturer's Barring List": "false",
      "Current Attendance %": "0.000",
      "Barring Process Attendance %": "0.000",
      "Last Updated By": " ",
      "Last Updated Date": " "
    }
  ],
  "exam_timetable": [

  ]
} 
```
` /bulletin_api `
``` 
[  
   {  
      "title":"Recruitment of Fresh IT Graduates by SoftwareONE Experts SDN. BHD.",
      "author":"Noor Hidaya binti Zaini  ",
      "url":"#inline_content4552",
      "contents":"\nFurther information on attachment.\n",
      "posted_date":"03 Jun 2015"
   }
]
```
` /login_mmls `
```
{  
   "message":"Successful Login",
   "profile":{  
      "name":"Hii Yong Lian",
      "faculty":"Faculty Of Com And Informatics"
   },
   "cookie":"eyJpdiI6IldrRmhDRG16d3lOUVwvWnN2MGdGVHFBPT0iLCJ2YWx1ZSI6ImJzWXpCZUhwYU85K2dYMVZ6Q3J1UU5lSnVnc1YyaGt6SWdEc2ZaRnNXQ1wvQkJaMG9RRXJWYnpRMmJKaUNISWJvc081TXBmdEJ0d3RYT214SnQ4dHkxdz09IiwibWFjIjoiOTQzZDRjZjdmMzFhNzcxNDI3NmRhMzVhYmFkYmUyMTBiNzAxMDM1M2RjYjA2ZTQzOTRlZGJiYTJjYTUzODUzNSJ9",
   "subjects":[  
      {  
         "uri":"https://mmls.mmu.edu.my/327:1427215013",
         "name":"MPU3206 - JAPANESE FOR BEGINNERS"
      },
      {  
         "uri":"https://mmls.mmu.edu.my/175:1427210675",
         "name":"MPU3413 - TAEKWONDO"
      },
      {  
         "uri":"https://mmls.mmu.edu.my/170:1427212552",
         "name":"TPT1201 - RESEARCH METHODS IN CS"
      }
   ],
   "token":"O5txWLTi3cCDK70WwNAfLXcHv7wdvijor67bx2Xx",
   "status":100
}
```
` /refresh_subject `
```
{  
   "id":null,
   "status":null,
   "name":"TPT1201 - RESEARCH METHODS IN CS",
   "weeks":[  
      {  
         "id":null,
         "subject_id":null,
         "title":"Week 10  (01/06/2015)",
         "announcements":[  
            {  
               "id":null,
               "title":"\nTC02 - Partial Course Marks - CORRECTED",
               "contents":" Dear TC02 Students, \n\n There are some major calculation mistakes in the partial marks (i.e. Quiz+Test+Assignment1) published earlier. It is now being corrected. Attached please find the corrected marks. Some of you may find that you now obtained lower marks than before, rest assured that the marking is fair and the marks published here are the correct ones.  \n\n Sorry for any inconviniences casued. \n\n \n\nAttachment : \n \n",
               "author":"Wong Ya Ping",
               "posted_date":"2015-05-29",
               "week_id":null,
               "subject_files":[  
                  {  
                     "id":null,
                     "file_name":"12037_RM_2014_15_T3_TC02_PartialMarks_150529.pdf",
                     "token":"9tV9n3TqmbbpgqIhQetZXwAJn1ytIR02Nux28hqa",
                     "content_id":"12037",
                     "content_type":null,
                     "file_path":"CYBER/TPT1201/announcement",
                     "subject_id":null,
                     "announcement_id":null
                  }
               ]
            },
            {  
               "id":null,
               "title":"\nTC02 : Next Tuesday (12th May) Lecture Class + Assignment 2 Presentation",
               "contents":" Dear Students of TC02 (Lecture Section under Dr. Wong Ya Ping and Dr. Ku Day Chyi), \n\n There shall not be any lecture class on Tuesday 12th May, 2015 11am-1pm. \n\n Instead this lecture time slot shall be used for Assignment 2 Presentation for Tutorial Section TT04 (under Dr. Wong Ya Ping) and TT05 (under Dr. Ku Day Chyi). Venues as follows: \n\n TT04 : AR1003 \n\n TT05 : AR2004 \n\n For TT06 : please follow instructions already given by Dr. Soon Lay Ki.  \n\n   \n",
               "author":"Wong Ya Ping",
               "posted_date":"2015-05-08",
               "week_id":null,
               "subject_files":[  

               ]
            }
         ]
      }
   ],
   "subject_files":[  
      {  
         "id":null,
         "file_name":"12037_RM_2014_15_T3_TC02_PartialMarks_150529.pdf",
         "token":"9tV9n3TqmbbpgqIhQetZXwAJn1ytIR02Nux28hqa",
         "content_id":"12037",
         "content_type":null,
         "file_path":"CYBER/TPT1201/announcement",
         "subject_id":null,
         "announcement_id":null
      }
   ]
}
```
