@RestResource(urlMapping='/createQuotes')
global class QuoteCreator {

    global class OpportunityWrapper {
        public Id opportunityId;
        public String name;
    }
    
    @HttpPost
    global static Map<String, String> createQuotes() {
        
        List<Quote__c> quotesToInsert = new List<Quote__c>();
        List<String> newQuoteIds = new List<String>();
        
        String requestBody = RestContext.request.requestBody.toString();
        List<OpportunityWrapper> opportunities = (List<OpportunityWrapper>) JSON.deserialize(
            requestBody,
            List<OpportunityWrapper>.class
        );
        
        for (OpportunityWrapper oppWrapper : opportunities) {
            Quote__c newQuote = new Quote__c(
                OpportunityId__c = oppWrapper.opportunityId,
                Name = oppWrapper.name
            );
            quotesToInsert.add(newQuote);
        }
        
        try {
            insert quotesToInsert;
            
            for (Quote__c q : quotesToInsert) {
                newQuoteIds.add(q.Id);
            }
            
            RestContext.response.statusCode = 201; 
            return new Map<String, String>{ 'ids' => String.join(newQuoteIds, ',') };
            
        } catch (DmlException e) {
            RestContext.response.statusCode = 400; 
            return new Map<String, String>{ 'error' => e.getMessage() };
        }
    }
}