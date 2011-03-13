##########################################################################
#General description about the service.
#Syntax: TITLE <TITLE_FOR_THE_SERVICE>
#  Example: TITLE .sge cluster.
##########################################################################
TITLE "An example of a clustered application"

##########################################################################
#Describe definition of each distinct component/virtual machine in the service. 
#Syntax: COMPONENT <UNIQUE_COMPONENT_NAME> <COMPONENT_TEMPLATE> <CARDINALITY>
#  Example: COMPONENT master master.template 2
#########################################################################
COMPONENT webserver /mincom/cloud/vmtemplate/gf/vm.gf.oel60_64_cpu_2_mem_512m_kvm 2
COMPONENT dbserver /mincom/cloud/vmtemplate/gf/vm.gf.oel60_64_cpu_2_mem_512m_kvm 1

#############################################################################
#Define dependencies if a harder synchronization is needed, i.e. do not submit 
#children until parent reaches RUNNING
#Syntax: PARENT <LIST OF COMPONENTS> CHILD <LIST OF COMPONENTS>
#  Example: PARENT master1, master2 CHILD node1, node2
#############################################################################
PARENT webserver CHILD dbserver


#############################################################################
#Define deployment order, if you need a soft synchronization point, e.g. to #instantiate IPs correctly.
#Syntax: DEPLOY <STRATEGY> <LIST OF COMPONENTS> where STRATEGY could be STRAIGHT, #REVERSE, or DONOTCARE.
#  Example: DEPLOY REVERSE master, node
#############################################################################
DEPLOY STRAIGHT webserver, dbserver

#############################################################################
#Optionally, we can override the default strategies of actions (SHUTDOWN, CANCEL, RESUME, SUSPEND, #STOP, and DELETE) 
#Example: 
#SHUTDOWN DONOTCARE
#SUSPEND REVERSE		
#CANCEL REVERSE 
#RESUME REVERSE 
#STOP DONOTCARE
#DELETE STRAIGHT
#############################################################################
