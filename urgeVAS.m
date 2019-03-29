function urgeVAS(h_obj,events,action)
%hsantermovas		HsanTermo, men med vas, vars förlopp sparas
%
%hsantermovas

%tok 090416
%
%Versionshistoria:
%090420
% 1. Vänta på knapptryck (medoc skall ha rätt temperatur)
% 2. Vänta på nästa scan trig.
% 3. Räkna ner sekunder till nästa scan och ge cue till försöksledaren
% 4. Ge cue till FP efter ytterligare en sekund
% 5. Mät rektionstid
% 6. Vänta på nästa knapptryck.
% Cue till FP skall vara en punkt.
% Obestämt antal stimulationer.
%
%090423a
% 1. 5s stimtid
% 2. Låt cue för FP komma efter 5s (slutet på stim).
%
%090423b
% 1. Visa cue efter 4s. Visa under 2s (1s efter stimslut).
%
%100318
% 1. Olika duration för olika stimtyper.
%
%100324
% 1. F7 m fl fungerar som space.
% 2. Responsräknare
%
%100406
% 1. Extra stimsekvens (nr 5) för test
%
%110531
% 1. Nytt namn (HsanTermo -> hsantermovas)
% 2. Svarspricken bort
% 3. Synkpulser från scanner registras inte längre
% 4. Inför en vas, aktiv under stimulationsperioden
% 5. Hela rörelseförloppet för vas registreras

global hsan;
global tim1;

if (nargin < 3) || isempty(action),
	action = 'INIT';
	if (nargin > 0) && isempty(h_obj), action = 'INIT'; end;
	if (nargin > 1) && isempty(events), action = 'INIT'; end;
end;

switch lower(action),
	case 'mousemotion',
		if hsan.stimon == 1,
			cp = get(hsan.hax1a,'CurrentPoint');
			cp = max([min([cp(1,1);10]);0]);
			hsan.nvas = hsan.nvas + 1;
			hsan.tvas(hsan.nvas,:) = [toc,cp];
			set(hsan.h1a2,'XData',[cp cp]);
		end;
	
	case 'init',								%initiering
		hsan = [];
		hsan.cbh = mfilename;
		hsan.p1 = fileparts(mfilename('fullpath'));
		hsan.PathNow = pwd;
		cd(hsan.p1);
		DoGlobalSetup;
		DoStimSeq;
		DoMeny01;
		if hsan.timer,
	    	feval(hsan.cbh,[],[],'TIMERSTART');
		end;
	case 'key',									%vid varje tangenttryckning eller volymtriggning
		a = get(hsan.hfig,'CurrentCharacter');
		%Använd F7 som input parallellt med space
		%if ~isempty(events) && strcmp(events.Key,'f7'), a = 32; end;
		%I version 6.5.1 kommer enbart en tom matris och alltså kan
		%godtycklig funktionstangent m fl användas
		if isempty(a), a = 32; end;
		if ~isempty(a),
			switch a,
				case {'r','g','y','b'},			%tangenttryckning eller fORP-tryckning
					resp = toc;
					%if ((hsan.stimon == 1) || (hsan.cueon == 1)) && ...
					%		(hsan.res(hsan.stim,6) == 0),
					if ((hsan.stimon == 1) || (hsan.cueon == 1)) && ...
							(hsan.res(hsan.stim,6) == 0),
						hsan.res(hsan.stim,6) = resp;
						hsan.response = hsan.response + 1;
						if hsan.StyrFig,		%uppdatering av response
							switch a,
								case 'r', set(hsan.hinfo(4),'Color','r');
								case 'g', set(hsan.hinfo(4),'Color','g');
								case 'y', set(hsan.hinfo(4),'Color','y');
								case 'b', set(hsan.hinfo(4),'Color','b');
							end;
							set(hsan.hinfo(4),'String',num2str(hsan.response));
						end;
					end;
				case {'t',char(39)},			%volymtriggning
					if hsan.vol == 0,			%första triggpulsen
						hsan.abstimeatstart = rem(now,1)*24*3600;	%starttid i s från 00:00:00 (för synk)
						tic;					%starta tidtagning
					end;
					hsan.vol = hsan.vol + 1;
					hsan.time_at_vol(hsan.vol) = toc;
					if hsan.run == 1,
						start(tim1);
						if hsan.StyrFig,
							set(hsan.hinfo(1),'String',num2str(hsan.countdown));
							set(hsan.hinfo(1),'Visible','on');
						end;
					end;		
					if hsan.StyrFig,			%uppdatering av volymsnummer
						set(hsan.hinfo(2),'String',num2str(hsan.vol));
					end;
					%behöver matriserna expanderas?
					if hsan.vol >= size(hsan.time_at_vol,1),
						hsan.time_at_vol = [hsan.time_at_vol;zeros(hsan.ex,1)];
					end;
					if hsan.stim >= size(hsan.res,1),
						hsan.res = [hsan.res;zeros(hsan.ex,7)];
					end;
				case 's',						%visa cue för FP
					switch hsan.run,
						case {2,3},
							hsan.countdown = hsan.countdown - 1;
							if hsan.StyrFig,
								set(hsan.hinfo(1),'String',num2str(hsan.countdown));
							end;
						case 4,
							hsan.stim = hsan.stim + 1;
							dd = mod(hsan.stim,hsan.numberofstim);
							if dd == 0,
								dd = hsan.numberofstim;
							end;
							hsan.duration = hsan.stimduration(dd);
							i1 = find(hsan.stimtypes == hsan.stimseq(dd,hsan.selectedstimseq));
							hsan.res(hsan.stim,2) = i1(1);	%stimtyp (numerisk)
							hsan.stimon = 1;
							%visa en röd rektangel (stimstart)
							set(hsan.hfig,'CurrentCharacter','v');
							feval(hsan.cbh,[],[],'KEY');
							drawnow;
							hsan.res(hsan.stim,4) = toc;
							if hsan.StyrFig,	%uppdatering av stimräknare
								set(hsan.hinfo(3),'String',...
									[num2str(hsan.stim),', ',...
									hsan.stimseq(dd,hsan.selectedstimseq)]);
							end;
							feval(hsan.cbh,[],[],'MOUSEMOTION');
							set(hsan.h1a2,'Visible','on');
							set(hsan.h1a3,'Visible','on');
							set(hsan.h1a4,'Visible','on');
							set(hsan.h1a5,'Visible','on');
						case 5,
							hsan.duration = hsan.duration - 1;
							if hsan.duration > 0,
								hsan.run = hsan.run - 1;
							else
								%starta INTE cue, spara volymnr och tid
								%set(hsan.hfig,'CurrentCharacter','k');
								%feval(hsan.cbh,[],[],'KEY');
								hsan.res(hsan.stim,5) = toc;
								hsan.res(hsan.stim,3) = hsan.time_at_vol(hsan.vol);
								hsan.res(hsan.stim,1) = hsan.vol;
								%hsan.cueon = 1;
							end;
						case 6,
							%avsluta stim
							hsan.stimon = 0;
							set(hsan.hfig,'CurrentCharacter','d');
							feval(hsan.cbh,[],[],'KEY');
							vaslog;				%logga all musaktivitet
							set(hsan.h1a2,'Visible','off');
							set(hsan.h1a3,'Visible','off');
							set(hsan.h1a4,'Visible','off');
							set(hsan.h1a5,'Visible','off');
						case 7,					%stoppa cue, aktivera space
							stop(tim1);
							hsan.cueon = 0;
							set(hsan.hfig,'CurrentCharacter','l');
							feval(hsan.cbh,[],[],'KEY');
							set(hsan.hhl(1),'Visible','on');
							hsan.run = 0;
					end;		
				case 'd',						%dölj alla figurer
					set(hsan.htext(1),'Visible','off');
					set(hsan.htext(2),'Visible','off');
					set(hsan.hrect,'Visible','off');
					set(hsan.hinfo(1),'Visible','off');
				case 'i',						%visa FP text 1
					set(hsan.htext(1),'Visible','on');
				case 'j',						%visa FP text 2
					set(hsan.htext(2),'Visible','on');
				case 'k',						%visa FP image
					set(hsan.himage,'Visible','on');
				case 'l',						%dölj FP image
					set(hsan.himage,'Visible','off');
				case 'v',						%visa svarsfigur
					set(hsan.hinfo(1),'Visible','off');
					if hsan.StyrFig,
						set(hsan.hrect,'Visible','on');
					end;
				case 32,						%space
					if hsan.run == 0,
						set(hsan.hhl(1),'Visible','off');
						hsan.countdown = hsan.TR;
						hsan.run = 1;
						%starta direkt genom att skicka ett t
						set(hsan.hfig,'CurrentCharacter','t');
						feval(hsan.cbh,[],[],'KEY');
					end;
				case 27,						%escape
					close(hsan.hfig);
			end;
		end;
	case 'exit',								%avsluta
		%stoppa timern (om den används)
		feval(hsan.cbh,[],[],'TIMEREXIT');
		%reaktionstider
		if ~isempty(hsan.res),
			i1 = hsan.res(:,6) ~= 0;			%där svar givits
			hsan.res(i1,7) = hsan.res(i1,6) - hsan.res(i1,5);
			i1 = hsan.res(:,1) == 0;			%tom tabell
			hsan.res(i1,:) = [];
		end;
		
		%konvertera vas till en kontinuerlig signal med konstant samplingsintervall
		hsan.time_vas_equidistant = [];
		hsan.vasT = 0.02;						%konstant samplingsintervall för vas (s)
		if ~isempty(hsan.time_vas),
			ttmax = 0;
			for ii = 1:size(hsan.time_vas,1),
				ttmax = max([ttmax;hsan.time_vas{ii,1}(end,1)-hsan.time_vas{ii,1}(1,1)]);
			end;
			vasx = (0:hsan.vasT:ttmax)';
			for ii = 1:size(hsan.time_vas,1),
				xx = vasx + hsan.time_vas{ii,1}(1,1);
				if size(hsan.time_vas{ii,1},1) > 1,
					yy = interp1q(hsan.time_vas{ii,1}(:,1),hsan.time_vas{ii,1}(:,2),xx);
				else
					yy = nan*xx;
					yy(1) = hsan.time_vas{ii,1}(1,2);
				end;
				if ii == 1,
					hsan.time_vas_equidistant = vasx;
				end;
				hsan.time_vas_equidistant = [hsan.time_vas_equidistant,yy];
			end;
		end;
	
		%spara data i en mat-fil
		cl = clock;
		fnam = ['hsantermovas_',date,'_',...
				num2str(cl(4),'%02d'),...
				num2str(cl(5),'%02d'),...
				num2str(fix(cl(6)),'%02d')];
		i1 = hsan.time_at_vol == 0;				%tom tabell
		hsan.time_at_vol(i1) = [];
		save(fnam,'hsan');
		
		%spara data i en log-fil
		fid = fopen([fnam,'.txt'],'at');
		hh = fix(hsan.abstimeatstart/3600);
		mm = fix((hsan.abstimeatstart - hh*3600)/60);
		ss = fix(hsan.abstimeatstart - hh*3600 - mm*60);
		ms = round((hsan.abstimeatstart - fix(hsan.abstimeatstart))*1000);
		fprintf(fid,'%%%s.txt, start at %02i:%02i:%02i.%03i\n',fnam,hh,mm,ss,ms);
		fprintf(fid,'%%Volume   \tStim type \tScan (s)  \tStim (s)  \tCue (s)   \tResp (s)  \tReaction (s)\n');
		fprintf(fid,'%%---------\t----------\t----------\t----------\t----------\t----------\t------------\n');
		for ii = 1:size(hsan.res,1),
			fprintf(fid,'%10i\t%10s\t%10.3f\t%10.3f\t%10.3f\t%10.3f\t%10.3f\n',...
				hsan.res(ii,1),hsan.stimtypes(hsan.res(ii,2)),hsan.res(ii,3:end));
		end;
		
		%spara vas-data med konstant samplingsintervall
		[mm,nn] = size(hsan.time_vas_equidistant);
		fprintf(fid,'\n\n%%Column 1 = time (s), column 2 - %i = vas (0-10) for stim 1 - %i\n',nn,nn-1);
		fprintf(fid,[repmat('%8.3f\t',1,nn),'\n'],hsan.time_vas_equidistant');
		
		fclose(fid);
		cd(hsan.PathNow);
	case 'timerstart',
		if ~isobject(tim1),
			tim1 = timer;
		end;
		if isobject(tim1),
			set(tim1,...
				'ExecutionMode','FixedRate',...
				'StartDelay',hsan.TTimer,...
				'Period',hsan.TTimer,...
				'TasksToExecute',11,...
				'TimerFcn',@HTTimer);
		end;
	case 'timerexit',
		if isobject(tim1),
			if isvalid(tim1),
				stop(tim1);
				delete(tim1);
			end;
			clear('tim1');
		end;
		clear global tim1;
	case 'resizefig',
		ddsize = get(hsan.hfig,'Position');
		aa = hsan.imagesize;
		bb = aa * (ddsize(3)-1)/(ddsize(4)-1);
		set(hsan.himage,...
			'XData',[0.5-aa 0.5+aa],...
			'YData',[0.5-bb 0.5+bb]);
end;

return;
%----------------------------------------------------------------------%
function DoGlobalSetup

global hsan;

%hsan.cbh = mfilename;
%hsan.p1 = fileparts(mfilename('fullpath'));
%hsan.PathNow = pwd;

hsan.MatlabVersion = version;					%några skillnader i kod?
hsan.DoExit = 0;
hsan.abstimeatstart = [];						%synktid
hsan.vol = 0;									%antal skannade volymer
hsan.stim = 0;									%antal givna stim
hsan.stimon = 0;								%anger om stim är aktiv
hsan.cueon = 0;									%anger om FP text visas
hsan.run = 0;									%anger att space har trycks
hsan.countdown = 0;								%nedräkning före stim
hsan.StyrFig = 1;								%1 om styrfigur skall visas
hsan.timer = 1;									%1 om timer ska användas
hsan.response = 0;								%responsräknare

hsan.TTimer = 1;								%Tid före cue (s)
hsan.TR = 3;									%TR (s)
hsan.ex = 100;									%antal rader att addera i taget
hsan.res = zeros(hsan.ex,7);					%design och resultat
hsan.time_at_vol = zeros(hsan.ex,1);			%tider för alla trigpulser


hsan.hfig = [];									%figure handle
hsan.hax = [];									%axes handle
hsan.hframe1 = [];								%ram handle
hsan.himage = [];								%en bild för FP
hsan.htext = [];								%2 texter för FP
hsan.hhl = [];									%2 rubriker för info
hsan.hinfo = [];								%3 info för försöksledaren
hsan.hrect = [];								%röd rektangel anger stimstart

hsan.hax1a = [];								%vas axlar
hsan.h1a1 = [];									%ram
hsan.h1a2 = [];									%rektangel
hsan.h1a3 = [];									%left text
hsan.h1a4 = [];									%right text
hsan.h1a5 = [];									%question
%ram och rektangel
hsan.xa = 0;
hsan.ya = 0;
hsan.xb = hsan.xa + 0.005;
hsan.yb = hsan.ya + 0.005;
hsan.xc = 10-2*hsan.xb;
hsan.yc = 1-2*hsan.yb;
%vas och loggning av vas
hsan.tvas = zeros(4096,2);						%temporärt vaslager (tid,vas)
hsan.nvas = 0;									%räknare av vaspunkter
hsan.time_vas = cell(0,0);						%vaslager

hsan.imagesize = 0.08;							%bildskala
%FP texter
hsan.text1 = '.';
hsan.text2 = '.';

%rubriker
hsan.hl(1) = {'press SPACE'};
hsan.hl(2) = {'volume'};
hsan.hl(3) = {'stim'};
hsan.hl(4) = {'response'};


%patientinfo
hsan.inf = [];
hsan.inf.fdate = datestr(now);
hsan.inf.project = 'HSAN-V Termo';
hsan.inf.name = '';
hsan.inf.id = '';
hsan.inf.height = '';
hsan.inf.weight = '';
hsan.inf.sex = '';
hsan.inf.group = '';
hsan.inf.sign = '';
hsan.inf.comment = '';

%inledande textsträngar
hsan.basestrings = {
	''
	''
	'Patient: '
	'ID: '
	'Längd (cm): '
	'Vikt (kg): '
	'Kön: '
	'Grupp: '
	'Sign: '
	'Kommentar: '};

%Välj en grupp av stimsekvenser.
%1: Första versionen
%2: Skapad 110826
select_stimseq = 2;

switch select_stimseq,
	case 1,
		hsan.stimseq = [
			'hchcH'
			'CHHCC'
			'HChch'
			'hcCHc'
			'CHchH'
			'chCHC'
			'hchch'
			'HCHCc'
			'hcHCH'
			'chchC'
			'CHCHh'
			'CHhcc'
			'HCCHH'
			'chchC'
			'CHCHh'
			'hchcc'
			'HCHCH'
			'HCchC'
			'chchh'
			'HCHCc'
			'hchcH'
			'chHCC'
			'chchh'
			'CHCHc'
			];
	case 2,
		hsan.stimseq = [
			'hhH'
			'HHH'
			'Hhh'
			'hHh'
			'HhH'
			'hHH'
			'hhh'
			'HHh'
			'hHH'
			'hhH'
			'HHh'
			'Hhh'
			'HHH'
			'hhH'
			'HHh'
			'hhh'
			'HHH'
			'HhH'
			'hhh'
			'HHh'
			'hhH'
			'hHH'
			'hhh'
			'HHh'
			];
end;

%tid att hålla stim (c, C, h och H)
hsan.stimhold = [
	5
	5
	3
	3
	];
hsan.stimtypes = 'cChH';
hsan.selectedstimseq = 0;
hsan.stimduration = [];
hsan.duration = 0;
hsan.numberofstim = size(hsan.stimseq,1);


return;
%----------------------------------------------------------------------%
function DoStimSeq

global hsan;

fprintf(1,'\n\nStim sequences:\n');
fprintf(1,'%4d\t',1:size(hsan.stimseq,2));
fprintf(1,'\n');
for ii = 1:size(hsan.stimseq,1),
	for jj = 1:size(hsan.stimseq,2),
		fprintf(1,'%2d-%s\t',ii,hsan.stimseq(ii,jj));
	end;
	fprintf(1,'\n');
end;
fprintf(1,'\n');

dd = zeros(length(hsan.stimhold),size(hsan.stimseq,2));
for ii = 1:size(hsan.stimseq,2),
	for jj = 1:length(hsan.stimtypes),
		dd(jj,ii) = sum(hsan.stimseq(:,ii) == hsan.stimtypes(jj));
	end;
end;
for ii = 1:length(hsan.stimtypes),
	for jj = 1:size(hsan.stimseq,2),
		fprintf(1,'%2d-%s\t',dd(ii,jj),hsan.stimtypes(ii));
	end;
	fprintf(1,'\n');
end;
fprintf(1,'\n');

ok = 0;
while ~ok,
	str2 = input(['Select a stim sequence (1 - ',num2str(size(hsan.stimseq,2)),'):'],'s');
	dd = str2double(str2);
	if (dd >= 1) && (dd <= size(hsan.stimseq,2)),
		hsan.selectedstimseq = dd;
		ok = 1;
	end;
end;

%fyll i stim durationer
hsan.stimduration = zeros(size(hsan.stimseq,1),1);
for ii = 1:size(hsan.stimseq,1),
	switch(hsan.stimseq(ii,hsan.selectedstimseq)),
		case 'c', hsan.stimduration(ii,1) = hsan.stimhold(1);
		case 'C', hsan.stimduration(ii,1) = hsan.stimhold(2);
		case 'h', hsan.stimduration(ii,1) = hsan.stimhold(3);
		case 'H', hsan.stimduration(ii,1) = hsan.stimhold(4);
	end;
end;

return;
%----------------------------------------------------------------------%
function vaslog
%logga vasdata

global hsan;

hsan.time_vas{hsan.stim,1} = hsan.tvas(1:hsan.nvas,:);
hsan.nvas = 0;
hsan.tvas(:,:) = 0;

return;
%----------------------------------------------------------------------%
function DoMeny01

global hsan;

%figur
ddsize = get(0,'ScreenSize');
fy = 0.07 * ddsize(4);				%figurposition
fh = ddsize(4) - fy;				%figurhöjd (pixels)
fx = 1;								%figurposition
fb = ddsize(3);						%figurbredd (hela skärmen)

hsan.hfig = figure('Visible','off');
set(hsan.hfig,...
    'HandleVisibility','Callback',...
    'MenuBar','none',...
    'Name',mfilename,...
    'NumberTitle','off',...
	'Units','pixels',...
    'Position',[fx fy fb fh], ...
	'DeleteFcn',{hsan.cbh,'EXIT'},...
	'KeyPressFcn',{hsan.cbh,'KEY'},...
	'ResizeFcn',{hsan.cbh,'RESIZEFIG'},...
	'WindowButtonMotionFcn',{hsan.cbh,'MOUSEMOTION'},...
	'Tag','Fig1_hMeny');
col = get(hsan.hfig,'Color');

%axes för hela figuren och ram
hsan.hax = axes('Parent',hsan.hfig,...
	'Position',[0 0 1 1],...
	'XLim',[0,1],...
	'YLim',[0,1],...
	'Visible','off');
hsan.hframe1 = line('Parent',hsan.hax,...
	'XData',[0.01 0.99 0.99 0.01 0.01],...
	'YData',[0.01 0.01 0.99 0.99 0.01],...
	'Visible','off');

%Handle för punkt för FP
iimax = 200;
dp = ones(iimax,iimax);
dp3(:,:,1) = dp * col(1);
dp3(:,:,2) = dp * col(2);
dp3(:,:,3) = dp * col(3);
for ii = 1:iimax,
	v = acos((ii-1)/(iimax-1));
	y1 = round(sin(v) * (iimax-1) + 1);
	dp3(1:y1,ii,1) = 0;
	dp3(1:y1,ii,2) = 0;
	dp3(1:y1,ii,3) = 1;
end;
dp3 = [dp3(:,end:-1:1,:),dp3];
dp3 = [dp3(end:-1:1,:,:);dp3];
aa = hsan.imagesize;
d2size = get(hsan.hfig,'Position');
bb = aa * (d2size(3)-1)/(d2size(4)-1);
hsan.himage = image('Parent',hsan.hax,...
	'CData',dp3,...
	'XData',[0.5-aa 0.5+aa],...
	'YData',[0.5-bb 0.5+bb],...
	'Visible','off');

%Handles för texter
pos = [0.5 0.5];
col = [0 0 1];
fs = 0.1;
hsan.htext(1) = text('Parent',hsan.hax,...
	'String',hsan.text1,...
	'Position',pos,...
	'HorizontalAlignment','Center',...
	'Color',col,...
	'FontUnits','normalized',...
	'FontSize',fs,...
	'Visible','off');
hsan.htext(2) = text('Parent',hsan.hax,...
	'String',hsan.text2,...
	'Position',pos,...
	'HorizontalAlignment','Center',...
	'Color',col,...
	'FontUnits','normalized',...
	'FontSize',fs,...
	'Visible','off');
col = [0 0 1];
fs = 0.04;
pos = [
	0.91 0.95
	0.11 0.95
	0.31 0.95
	0.56 0.95
	];
for ii = 1:4,
	hsan.hinfo(ii) = text('Parent',hsan.hax,...
		'String','0',...
		'Position',pos(ii,:),...
		'Color',col,...
		'FontUnits','normalized',...
		'FontSize',fs,...
		'Visible','on');
	if hsan.StyrFig == 0,
		set(hsan.hinfo(ii),'Visible','off');
	end;
end;
set(hsan.hinfo(1),'Visible','off');
col = [0 0 0];
fs = 0.02;
pos = [
	0.75 0.95
	0.01 0.95
	0.21 0.95
	0.46 0.95
	];
for ii = 1:4,
	hsan.hhl(ii) = text('Parent',hsan.hax,...
		'String',hsan.hl(ii),...
		'Position',pos(ii,:),...
		'Color',col,...
		'FontUnits','normalized',...
		'FontSize',fs,...
		'Visible','on');
	if hsan.StyrFig == 0,
		set(hsan.hhl(ii),'Visible','off');
	end;
end;


%Handle för rektangel
hsan.hrect = rectangle('Parent',hsan.hax,...
	'Position',[0.91 0.94 0.05 0.03],...
	'FaceColor',[1 0 0],...
	'Visible','off');

set(hsan.hfig,...
    'Visible','on');


%axlar för vas
figcol = get(hsan.hfig,'Color');
hsan.hax1a = axes('Parent',hsan.hfig,...
	'Units','normalized',...
	'Position',[0.2 0.3 0.6 0.1],...
	'XLim',[0 10],...
	'YLim',[0 1],...
	'Visible','off');
%en ram
hsan.h1a1 = rectangle('Parent',hsan.hax1a,...
	'Position',[hsan.xb hsan.yb hsan.xc hsan.yc],...
	'EdgeColor',[0 0 0],...
	'FaceColor',figcol,...
	'LineWidth',2,...
	'Visible','on',...
	'Tag','hsan_Frame');
%rektangel
%hsan.h1a2 = rectangle('Parent',hsan.hax1a,...
%	'Position',[hsan.xb hsan.yb hsan.xc hsan.yc],...
%	'FaceColor',[1 1 1] * 0.5,...
%	'Visible','off',...
%	'ButtonDownFcn',{hsan.cbh,'RECTDOWN'},...
%	'Tag','hsan_Rect');
%linje
hsan.h1a2 = line('Parent',hsan.hax1a,...
	'XData',[5 5],...
	'YData',[-0.2 1.2],...
	'Color',[1 0 0],...
	'LineWidth',4,...
	'Clipping','off',...
	'Visible','off',...
	'Tag','hsan_Line');
%question
hsan.h1a5 = text('Parent',hsan.hax1a,...
	'String','Behov att dra undan handen',...
	'Position',[5 +1.5],...
	'HorizontalAlignment','Center',...
	'VerticalAlignment','Bottom',...
	'FontUnits','normalized',...
	'FontSize',0.4,...
	'Visible','off');
%left text
hsan.h1a3 = text('Parent',hsan.hax1a,...
	'String','Inget behov',...
	'Position',[0 -0.5],...
	'HorizontalAlignment','Center',...
	'VerticalAlignment','Top',...
	'FontUnits','normalized',...
	'FontSize',0.4,...
	'Visible','off');
%Right text
hsan.h1a4 = text('Parent',hsan.hax1a,...
	'String','Mycket starkt behov',...
	'Position',[10 -0.5],...
	'HorizontalAlignment','Center',...
	'VerticalAlignment','Top',...
	'FontUnits','normalized',...
	'FontSize',0.4,...
	'Visible','off');

return;
%----------------------------------------------------------------------%
function HTTimer(h_obj,event)
%HTTimer				Generera cue

global hsan;

hsan.run = hsan.run + 1;
set(hsan.hfig,'CurrentCharacter','s');
feval(hsan.cbh,[],[],'KEY');

return;
