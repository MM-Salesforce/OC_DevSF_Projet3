/**
 * @description Données renvoyées par une recherche de Cases pour un Account.
 * @author MM
 * @last modified by MM on 05-11-2026
 **/
public class CaseSearchResult {
    /**
     * Cases renvoyés au composant pour affichage, dans une limite de 100 enregistrements.
     * AuraEnabled inclut cette propriété dans la réponse Apex sérialisée consommée par le LWC.
     **/
    @AuraEnabled
    public List<Case> cases { get; set; }

    /**
     * Vaut true si le sélecteur a trouvé une 101e correspondance, prouvant que plus de 100 Cases correspondent.
     * Le LWC utilise ce booléen pour inviter l'utilisateur à préciser sa recherche.
     **/
    @AuraEnabled
    public Boolean limitReached { get; set; }
}
