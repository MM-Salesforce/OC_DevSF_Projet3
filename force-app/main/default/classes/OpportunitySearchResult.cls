/**
 * @description DTO (Data Transfer Object) renvoyé par une recherche d'Opportunities pour un Account.
 * @author MM
 * @last modified by MM on 05-11-2026
 **/
public class OpportunitySearchResult {
    /**
     * Opportunities renvoyées pour affichage, dans une limite de 100.
     * AuraEnabled inclut cette propriété dans la réponse sérialisée consommée par le LWC.
     **/
    @AuraEnabled
    public List<Opportunity> opportunities { get; set; }

    /**
     * Vaut true si le sélecteur a trouvé une 101e correspondance et l'a retirée de la liste affichée.
     * Le LWC utilise ce booléen pour indiquer à l'utilisateur que seules les 100 premières lignes sont visibles.
     **/
    @AuraEnabled
    public Boolean limitReached { get; set; }
}
