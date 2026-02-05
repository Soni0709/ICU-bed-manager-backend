class BedsController < ApplicationController
  before_action :set_bed, only: [:assign, :discharge, :clean]
  
  # GET /beds
  def index
    beds = Bed.all.order(:bed_number)
    render json: beds
  end
  
  # POST /beds/:id/assign
  def assign
    @bed.assign_patient!(params[:patient_name], params[:urgency_level])
    render json: @bed
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
  
  # POST /beds/:id/discharge
  def discharge
    @bed.discharge_patient!
    render json: @bed
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
  
  # POST /beds/:id/clean
  def clean
    @bed.mark_cleaned!
    render json: @bed
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
  
  
  private
  
  def set_bed
    @bed = Bed.find(params[:id])
  end
end