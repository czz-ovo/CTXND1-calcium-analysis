function dffaWrite(T,base,c)
writetable(T,[base '.csv']);
if c.WriteXlsx
    try
        writetable(T,[base '.xlsx']);
    catch ME
        warning('dffAnalysis:ExcelWrite','CSV saved; Excel export failed: %s',ME.message);
    end
end
end
