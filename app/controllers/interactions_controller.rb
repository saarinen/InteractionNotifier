class InteractionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  # GET This method taked the 
  def get_interactions
  end

  # PUT This method taked the FHIR patient ID and makes a call to the EHR 
  # to grab the patients prescriptions
  def update_patient
    if params[:patient_id].empty?
      not_found
    end

    # Retrieve a list of medications
    @medications = get_medications(params[:patient_id])
  end

  private

  # Make a call to FHIR to get patient prescriptions
  def get_medications(patient_id)
    medications = Array.new()
    prescriptions = HTTParty.get("http://polaris.i3l.gatech.edu:8080/gt-fhir-webapp/base/MedicationPrescription?patient._id=#{patient_id}")
    prescriptions['entry'].each do |entry|
      resource = entry['resource']
      medication = resource['medication']
      reference = medication['reference']
      medications.push(get_medication_code(reference))
    end
    return medications
  end

  def get_medication_code(reference_id)
    medication = HTTParty.get("http://polaris.i3l.gatech.edu:8080/gt-fhir-webapp/base/#{reference_id}")
    codings = medication['code']['coding']
    codings.each do |coding|
      if coding['system'].eql? "http://www.nlm.nih.gov/research/umls/rxnorm"
        return coding['code']
      end
    end
  end
end
