class InteractionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  # GET This method taked the FHIR patient ID and makes a call to the EHR 
  # to grab the patients prescriptions
  def update_patient
    if params[:patient_id].empty?
      not_found
    end

    # Retrieve a list of medications
    #@medications = get_medications(params[:patient_id])
    # Hardcoding medications as FHIR is down
    @medications = [207106,152923,656659]
    #@medications = []

    # Make request to RxNav
    @interactions = get_interactions(@medications)

    @interactionGroup = @interactions['fullInteractionTypeGroup']

    unless @interactionGroup.nil?
      @warnings = Array.new()
      @interactionGroup.each do |interaction|
        interaction_types = interaction['fullInteractionType']
        interaction_types.each do |interaction_type|
          comment = ""
          interaction_type['interactionPair'].each do |pair|
            comment = pair['description']
          end
          @warnings.append(comment)
        end
      end
      publish_interactions_to_sns(@warnings.join(', '), params[:patient_id]) 
    end
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

  def get_interactions(medications)
    interactions = HTTParty.get("https://rxnav.nlm.nih.gov/REST/interaction/list.json?rxcuis=#{medications.join('+')}")
    return JSON.parse(interactions.body)
  end

  def publish_interactions_to_sns(payload, patient_id)
    sns = Aws::SNS::Client.new(region: 'us-east-1')
    resp = sns.publish({
      topic_arn: "arn:aws:sns:us-east-1:068709296373:rx_interaction_notification",
      message: payload.to_s,
      subject: "Interaction Warning for patient: #{patient_id}",
    })
  end
end
