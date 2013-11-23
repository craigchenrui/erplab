% PURPOSE: subroutine for pop_fourierp.m pop_fourieeg.m
%          calculates Single-Sided Power Spectrum of a dataset
%
% FORMAT
%
% varargout = fourieeg(EEG, chanArray, f1, f2, np, latwindow)
%
% INPUTS
%
%   EEG          - continuous or epoched dataset
%   chanArray    - channel to be processed
%   f1           - lower frequency limit
%   f2           - upper frequency limit
%   np           - number of points for FFT
%   latwindow    - time window of interest, in msec, for epoched data.
%
%
% OUTPUT:
%
%   captured     - flag. 1 means data has a flatline or blocking behavior.
%
%
% EXAMPLE
%
% [ym f] = fourieeg(EEG,chanArray,f1,f2) returns the squared module, ym, of the FFT output
% of your dataset, evaluated at channel chanArray, between the frequencies f1 and f2 (in Hz).
% f contains the frequency range.
%
% [ym f] = fourieeg(EEG,chanArray,f1) returns the squared module of the FFT output
% of your dataset, evaluated at channel chanArray, between the frequencies f1 (in
% Hz) and fs/2 (fnyquist).f contains the frequency range.
%
% [ym f] = fourieeg(EEG,chanArray) returns the squared module of the FFT output
% of your dataset, evaluated at channel chanArray, between ~0 hz and fs/2
% (fnyquist). f contains the frequency range.
%
% [ym f] = fourieeg(EEG) returns the squared module of the FFT output
% of your dataset, evaluated at channel 1, between the frequencies f1 (in
% Hz) and fs/2 (fnyquist). f contains the frequency range.
%
% ym = fourieeg(EEG...) returns only the squared module of the FFT output
% of your dataset.
%
% ... = fourieeg(EEG,chanArray,f1,f2,np, latwindow).
%
% fourieeg(EEG...) plots the Single-Sided Power Spectrum of your
% dataset.
%
%
% See also fft.
%
%
% *** This function is part of ERPLAB Toolbox ***
% Author: Javier Lopez-Calderon & Steven Luck
% Center for Mind and Brain
% University of California, Davis,
% Davis, CA
% 2009

%b8d3721ed219e65100184c6b95db209bb8d3721ed219e65100184c6b95db209b
%
% ERPLAB Toolbox
% Copyright � 2007 The Regents of the University of California
% Created by Javier Lopez-Calderon and Steven Luck
% Center for Mind and Brain, University of California, Davis,
% javlopez@ucdavis.edu, sjluck@ucdavis.edu
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

function varargout = fourieeg(EEG, chanArray, binArray, f1, f2, np, latwindow, includelege)
if nargin < 1
        help fourieeg
        if nargout == 1
                varargout{1} = [];
        elseif nargout == 2
                varargout{1} = [];
                varargout{2} = [];
        else
                return
        end
        return
end
if nargin<8
        includelege = 1; % 1 means include leyend, 0 means do not...
end
if nargin<7
        latwindow = [EEG.xmin EEG.xmax]*1000; % msec
end
if nargin<6
        np = [];
end
if nargin<5
        f2 = EEG.srate/2;
end
if nargin<4
        f1 = 0;
end
if nargin<3
        binArray = [];
end
if nargin<2
        chanArray = 1;
end
if isempty(EEG(1).data)
        msgboxText =  'fourieeg() error: cannot filter an empty dataset';
        title_msg  = 'ERPLAB: fourieeg():';
        errorfound(msgboxText, title_msg);
        return
end
disp('Working...')
fs    = EEG.srate;
fnyq  = fs/2;
nchan = length(chanArray);
if isempty(EEG.epoch)  % continuous data
        sizeeg = EEG.pnts;
        L      = fs*5 ;  %5 seconds of signal
        nwindows = round(sizeeg/L);
        if isempty(np)
                NFFT   = 2^nextpow2(L);
        else
                NFFT = 2*np;
        end
        f      = fnyq*linspace(0,1,NFFT/2);
        ffterp = zeros(nwindows, NFFT/2, nchan);
        for k=1:nchan
                a = 1; b = L; i = 1;
                while i<=nwindows && b<=sizeeg
                        y = detrend(EEG.data(chanArray(k),a:b));
                        Y = fft(y,NFFT)/L;
                        ffterp(i,:,k) = 2*abs(Y(1:NFFT/2));
                        a = b - round(L/2); % 50% overlap
                        b = b + round(L/2); % 50% overlap
                        i = i+1;
                end
        end
        msgn = 'whole';
else   % epoched data
        indxtimewin = ismember_bc2(EEG.times, EEG.times(EEG.times>=latwindow(1) & EEG.times<=latwindow(2)));
        datax  = EEG.data(:,indxtimewin,:);
        L      = length(datax); %EEG.pnts;
        ntrial = EEG.trials;
        if isempty(np)
                NFFT   = 2^nextpow2(L);
        else
                NFFT = 2*np;
        end
        f = fnyq*linspace(0,1,NFFT/2);
        ffterp = zeros(ntrial, NFFT/2, nchan);
        for k=1:nchan
                for i=1:ntrial
                        if ~isempty(binArray) && isfield(EEG.epoch,'eventbini')
                                if length(EEG.epoch(i).eventlatency) == 1
                                        numbin = EEG.epoch(i).eventbini; % index of bin(s) that own this epoch (can be more than one)
                                elseif length(EEG.epoch(i).eventlatency) > 1
                                        indxtimelock = find(cell2mat(EEG.epoch(i).eventlatency) == 0); % catch zero-time locked event (type),
                                        [numbin]  = [EEG.epoch(i).eventbini{indxtimelock}]; % index of bin(s) that own this epoch (can be more than one) at time-locked event.
                                        numbin    = unique_bc2(numbin(numbin>0));
                                else
                                        numbin =[];
                                end
                                if iscell(numbin)
                                        numbin = numbin{:}; % allows multiples bins assigning
                                end
                        elseif ~isempty(binArray) && ~isfield(EEG.epoch,'eventbini')
                                numbin =[];
                        else
                                numbin =[];
                        end                      
                        if isempty(binArray) || (~isempty(binArray) && ~isempty(numbin) && ismember_bc2(numbin, binArray))                               
                                y = detrend(datax(chanArray(k),:,i));
                                Y = fft(y,NFFT)/L;
                                ffterp(i,:,k) = abs(Y(1:NFFT/2)).^2; % power
                                if rem(NFFT, 2) % odd NFFT excludes Nyquist point
                                        ffterp(i,2:end,k) = ffterp(i,2:end,k)*2;
                                else
                                        ffterp(i,2:end-1,k) = ffterp(i,2:end-1,k)*2;
                                end
                        end
                end
        end
        msgn = 'all epochs';
end
avgfft = mean(ffterp,1);
avgfft = mean(avgfft,3);
f1sam  = round((f1*NFFT/2)/fnyq);
f2sam  = round((f2*NFFT/2)/fnyq);
if f1sam<1
        f1sam=1;
end
if f2sam>NFFT/2
        f2sam=NFFT/2;
end
fout = f(f1sam:f2sam);
yout = avgfft(1,f1sam:f2sam);
if nargout ==1
        varargout{1} = yout;
elseif nargout == 2
        varargout{1} = yout;
        varargout{2} = fout;
else
        %
        % Plot single-sided amplitude spectrum.
        %
        fname = EEG.setname;
        h = figure('Name',['<< ' fname ' >>  ERPLAB Amplitude Spectrum'],...
                'NumberTitle','on', 'Tag','Plotting Spectrum',...
                'Color',[1 1 1]);        
        plot(fout,yout)
        axis([min(fout)  max(fout)  min(yout)*0.9 max(yout)*1.1])
        
        if includelege
                if isfield(EEG.chanlocs,'labels')
                        lege = sprintf('EEG Channel: ');
                        for i=1:length(chanArray)
                                lege =   sprintf('%s %s', lege, EEG.chanlocs(chanArray(i)).labels);
                        end
                        lege = sprintf('%s *%s', lege, msgn);
                        legend(lege)
                else
                        legend(['EEG Channel: ' vect2colon(chanArray,'Delimiter', 'off') '  *' msgn])
                end
        end
        title('Single-Sided Amplitude Spectrum of y(t)')
        xlabel('Frequency (Hz)')
        ylabel('|Y(f)|')
end
