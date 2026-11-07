
/**
 * @description Expose la recherche de Cases d'un Account au LWC accountCasesSearcher.
 * @author MM
 * @group EG Manufacturing
 * @last modified by MM on 05-11-2026
 **/
public with sharing class AccountCasesController {

    /**
     * @description Recherche les Cases d'un Account dont le Subject contient le terme indiqué.
     * @param accountId ID de l'Account parent fourni par le contexte de la record page du LWC.
     * @param subjectSearchTerm Texte saisi par l'utilisateur dans le champ de recherche.
     * @return Cases correspondants (100 au maximum) et indicateur de résultats supplémentaires.
     **/
    // AuraEnabled expose cette méthode Apex au LWC ; cacheable=true est possible car elle ne lit que des données.
    @AuraEnabled(cacheable=true)
    public static CaseSearchResult findCasesBySubject(Id accountId, String subjectSearchTerm) {
        // Point d'entrée appelé par le LWC. Le sélecteur gère le SOQL et l'application des règles d'accès.
        // Renvoyer son DTO sans le modifier préserve la structure de réponse attendue par JavaScript.
        return CaseSelector.getCasesByAccountIdAndSubject(accountId, subjectSearchTerm);
    }
}
