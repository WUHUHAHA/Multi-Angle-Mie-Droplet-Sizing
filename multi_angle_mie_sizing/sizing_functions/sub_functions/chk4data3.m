function [result ind]=chk4data3(theta_in,phi_in,half_angle,gamma_ref,...
    xi,calc_meth,sigma,dist_type,sz3_data)
%
% Copyright (C) 2012, Stephen D. LePera.  GNU General Public License, v3.
% Terms available in GPL_v3_license.txt, or <http://www.gnu.org/licenses/>

tol=1e-6;

if isstruct(sz3_data)==1
    
    ind=find(theta_in-tol < [sz3_data.theta] & ...
        theta_in+tol > [sz3_data.theta] &...
        phi_in-tol < [sz3_data.phi] & phi_in+tol > [sz3_data.phi] &...
        half_angle-tol < [sz3_data.half_angle] &...
        half_angle+tol > [sz3_data.half_angle] &...
        sigma-tol < [sz3_data.sigma] & sigma+tol > [sz3_data.sigma] & ...
        1==strcmp(dist_type,{sz3_data.dist_type}) & ...
        1==strcmp(gamma_ref,{sz3_data.gamma_ref}) & ...
        1==strcmp(xi,{sz3_data.xi}) & ...
        1==strcmp(calc_meth,{sz3_data.method}) );
    
    if size(ind,2)==0
        result=0;
    elseif size(ind,2)>1
        error([' Multiple matches found in sz3_data.  Severe error;',...
            ' This should not be possible.']);
    else
        result=sz3_data(ind);
    end
    
else
    result=0;
    ind='NaN';
end