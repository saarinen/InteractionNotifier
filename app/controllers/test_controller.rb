class TestController < ApplicationController
  def create_test_patient
    test_patient = {
      "resourceType":"Patient",
      "name":[
        {
          "family":[
            "Snow"
          ],
          "given":[
            "John"
          ]
        }
      ],
      "gender":"male",
      "birthDate":"1978-10-23",
      "address":[
        {
          "line":[
            "13800 162nd Ave NE"
          ],
          "city":"Woodinville",
          "state":"WA",
          "postalCode":"98072"
        }
      ],
      "active":true
    }

    patient_result = HTTParty.post("http://polaris.i3l.gatech.edu:8080/gt-fhir-webapp/base/Patient", 
                              :body => test_patient.to_json,
                              :headers => { 'Content-Type' => 'application/json' } )

    @patient_id = get_entity_id(patient_result.headers['location'])

    # Create patient encounter

    encounter = {
        "resourceType":"Encounter",
        "status":"finished",
        "class":"outpatient",
        "patient":{
          "reference":"Patient/879"
        },
        "period":{
          "start":"2015-11-30T12:00:00",
          "end":"2015-11-30T12:30:00"
        },
        "location":[
          {
            "location":{
            "reference":"Location/1"
            }
          }
        ],
        "serviceProvider":{
        "reference":"Organization/1"
      }
    }

    encounter_result = HTTParty.post("http://polaris.i3l.gatech.edu:8080/gt-fhir-webapp/base/Encounter", 
                              :body => encounter.to_json,
                              :headers => { 'Content-Type' => 'application/json' } )

    @encounter_id = get_entity_id(patient_result.headers['location'])

    # create medication persriptions
  end

  private

  def get_entity_id(entity_location_url)
    url_parts = entity_location_url.split('/')
    return url_parts.last
  end
end
