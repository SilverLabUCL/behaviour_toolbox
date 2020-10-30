function pupil = format_pupil_output(obj)
   % pupil = obj.pupil.LongAxis .* obj.pupil.ShortAxis * pi;
	if isprop(obj, 'pupil')
        pupil = obj.pupil.LongAxis;
        pupil = [pupil, obj.parent_h.parent_h.t];
    else
        pupil = NaN(size(obj.parent_h.parent_h.t, 1), 2);
	end
end

