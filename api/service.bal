import ballerina/http;
import ballerina/log;
import ballerina/graphql;

final GlobalDataClient globalDataClient = check new ("https://3a907137-52a3-4196-9e0d-22d054ea5789-dev.e1-us-east-azure.choreoapis.dev/mhbw/global-data-graphql-api/1.0.0/graphql");


# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

    # A resource for generating greetings
    # + person - the input Person record
    # + return - Student record with associated data
    resource function post student_applicant(@http:Payload Person person) returns CreateStudentApplicantResponse|error {
        CreateStudentApplicantResponse|graphql:ClientError createStudentApplicantResponse = globalDataClient->createStudentApplicant(person);
        return createStudentApplicantResponse;
    }

    resource function post applicant_consent(@http:Payload ApplicantConsent applicantConsent) returns CreateStudentApplicantConsentResponse|error {
        CreateStudentApplicantConsentResponse|graphql:ClientError createStudentApplicantConsentResponse = globalDataClient->createStudentApplicantConsent(applicantConsent);
        return createStudentApplicantConsentResponse;
    }

    resource function get organization_vacancies/[string name]() returns GetOrganizationVacanciesResponse|error {
        GetOrganizationVacanciesResponse|graphql:ClientError getOrganizationVacanciesResponse = globalDataClient->getOrganizationVacancies(name);
        return getOrganizationVacanciesResponse;
    }

    resource function get student_vacancies/[string name]() returns json|error {
        GetOrganizationVacanciesResponse|graphql:ClientError getOrganizationVacanciesResponse = globalDataClient->getOrganizationVacancies(name);
        
        if(getOrganizationVacanciesResponse is GetOrganizationVacanciesResponse) {
             map<json> org_structure = check getOrganizationVacanciesResponse.toJson().ensureType();
             foreach var organizations in org_structure {
                json[]|error org_data = organizations.organizations.ensureType();
                
                if(org_data is json[]) {
                    foreach var data in org_data {
                        json[]|error child_orgs = data.child_organizations.ensureType();
                        if (child_orgs is json[]) {
                            foreach var child_org in child_orgs {
                            
                                json[]|error vacancies =  child_org.vacancies.ensureType();
                                if (vacancies is json[]) {
                                    foreach var vacancy in vacancies {
                                        log:printInfo("Vacancy " + vacancy.toString());
                                        json|error aviya_type =  vacancy.avinya_type.ensureType();
                                        if !(aviya_type is error) {
                                            string|error global_type = aviya_type.global_type.ensureType();
                                            string|error  foundation_type =  aviya_type.foundation_type.ensureType();
                                            string|error  focus =aviya_type.focsus.ensureType();
                                            if(global_type is string && foundation_type is string && focus is string) {
                                                log:printInfo("applicant" + "applicant".equalsIgnoreCaseAscii(global_type).toString());
                                                log:printInfo("student" + "student".equalsIgnoreCaseAscii(global_type).toString());
                                                log:printInfo(focus);
                                            }
                                        }

                                        Vacancy vacancy_record = check vacancy.cloneWithType(Vacancy);
                                        log:printInfo(vacancy_record?.avinya_type?.global_type.toString());
                                        log:printInfo(vacancy_record?.avinya_type?.foundation_type.toString());
                                        string foundation_type = vacancy_record?.avinya_type?.global_type?: "";
                                        string global_type = vacancy_record?.avinya_type?.foundation_type?: "";
                                        if(global_type.equalsIgnoreCaseAscii("applicant") && 
                                            foundation_type.equalsIgnoreCaseAscii("student")) {
                                            log:printInfo("Student vacancy");
                                        }
                                        log:printInfo("vacancy_record " + vacancy_record.toString());
                                    }
                                    
                                    return vacancies.toJson();
                                } else {
                                    log:printError("Error vacancies: " + vacancies.toString());
                                }
                                
                            }
                        
                        } else {
                            log:printError("Error child_orgs: " + child_orgs.toString());
                        }
                    }
                } else {
                    log:printError("Error org_data: " + org_data.toString());
                }

             } 
        } else {
            return error("Error: student vacancies not found. " + getOrganizationVacanciesResponse.toString());
        }
    }
    
}
