function pupil = format_pupil_output(obj)
    pupil = obj.pupil;
    if isstruct(pupil)
    	pupil = pupil.LongAxis;
    end
end

