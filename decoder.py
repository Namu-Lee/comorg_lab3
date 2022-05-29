from ctypes import *

def decoder(file_directory):
    f = open(file_directory+"/inst.mem","r")
    w = open(file_directory+"/decode_inst.txt","w")

    # def int32(x):
    #     return -(0xffffffff+1 - x)
    
    def switch_R(funct3,funct7):
        if(funct3==0):
            if(funct7==32):
                return "sub"
            else:
                return "add"
        elif(funct3==4):
            return "xor"
        elif(funct3==6):
            return "or"
        elif(funct3==7):
            return "and"
        elif(funct3==1):
            return "sll"
        elif(funct3==5):
            if(funct7==32):
                return "sra"
            else:
                return "srl"
        elif(funct3==2):
            return "slt"
        elif(funct3==3):
            return "sltu"
        else:
            return "unknown"
    def switch_I(funct3):
        type = {0 : "addi", 4: "xori", 6 : "ori", 7:"andi", 1:"slli",5:"srli",2:"slti",3:"sltiu"}.get(funct3, "unknown")
        return type
    def switch_L(funct3):
        type = {0 : "lb", 1: "lh", 2 : "lw",4:"lbu", 5:"lhu"}.get(funct3, "unknown")
        return type
    def switch_S(funct3):
        type = {0 : "sb", 1: "sh", 2 : "sw"}.get(funct3, "unknown")
        return type
    def switch_B(funct3):
        type = {0 : "beq", 1: "bne", 4 : "blt", 5: "bge", 6: "bltu", 7: "bgeu"}.get(funct3, "unknown")
        return type

    PC=0
    arr_type=[]
    arr_rd=[]
    arr_rs1=[]
    arr_rs2=[]
    arr_imm=[]
    arr_instruction=[]

    type='unknown'
    rs1=0
    rs2=0
    rd=0
    imm=0

    while True:
        line = f.readline()
        if not line: break

        
        if(line[25:32]=="0110011"):# R
            type='R_type'
            funct7=int(line[0:7],2)
            rs2=int(line[7:12],2)
            rs1=int(line[12:17],2)
            funct3=int(line[17:20],2)
            rd=int(line[20:25],2)
            type=str(switch_R(funct3,funct7))
            print(str(PC) + " : " + type + ' rd= 0x' + str(rd) + ' rs1= 0x' + str(rs1) + ' rs2= 0x' + str(rs2) ,file=w)
            arr_instruction.append(str(PC) + " : " + type + ' rd= 0x' + str(rd) + ' rs1= 0x' + str(rs1) + ' rs2= 0x' + str(rs2))
            
        elif(line[25:32]=="0010011"):# I
            type='I_type'
            imm=int(line[0]*20+line[0:12],2)
            rs1=int(line[12:17],2)
            funct3=int(line[17:20],2)
            rd=int(line[20:25],2)
            type=str(switch_I(funct3))
            print(str(PC) + " : "+type + " rd= 0x" + str(rd) +  " rs1= 0x" + str(rs1) + " imm= " + str(c_int32(imm).value) ,file=w)
            arr_instruction.append(str(PC) + " : "+type + " rd= 0x" + str(rd) +  " rs1= 0x" + str(rs1) + " imm= " + str(c_int32(imm).value))


        elif(line[25:32]=="0000011"): #Load
            type='Load'
            imm=int(line[0]*20+line[0:12],2)
            rs1=int(line[12:17],2)
            funct3=int(line[17:20],2)
            rd=int(line[20:25],2)
            type=str(switch_L(funct3))
            print(str(PC) + " : "+type + " rd= 0x" + str(rd) +  " rs1= 0x" + str(rs1) + " imm= " + str(c_int32(imm).value) ,file=w)
            arr_instruction.append(str(PC) + " : "+type + " rd= 0x" + str(rd) +  " rs1= 0x" + str(rs1) + " imm= " + str(c_int32(imm).value))

        elif(line[25:32]=="0100011"): #Store
            type='Store'
            imm=int(line[0]*20+line[0:7]+line[20:25],2)
            funct3=int(line[17:20],2)
            rs2=int(line[7:12],2)
            rs1=int(line[12:17],2)
            type=str(switch_S(funct3))
            print(str(PC) + " : "+type + " rs1= 0x" + str(rs1) +  " rs2= 0x" + str(rs2) + " imm= " + str(c_int32(imm).value),file=w)
            arr_instruction.append(str(PC) + " : "+type + " rs1= 0x" + str(rs1) +  " rs2= 0x" + str(rs2) + " imm= " + str(c_int32(imm).value))

        elif(line[25:32]=="1100011"): #Branch 1100011
            type='Branch'
            imm=int(line[0]*19+line[0]+line[24]+line[1:7]+line[20:24]+'0',2)
            funct3=int(line[17:20],2)
            rs2=int(line[7:12],2)
            rs1=int(line[12:17],2)
            type=str(switch_B(funct3))
            print(str(PC) + " : "+type + " rs1= 0x" + str(rs1) +  " rs2= 0x" + str(rs2) + " imm= " + str(c_int32(imm).value) ,file=w)
            arr_instruction.append(str(PC) + " : "+type + " rs1= 0x" + str(rs1) +  " rs2= 0x" + str(rs2) + " imm= " + str(c_int32(imm).value))

        elif(line[25:32]=="1101111"): #JAL 1101111
            type='jal'
            rd=int(line[20:25],2)
            imm=int(line[0]*11+line[0]+line[12:20]+line[11]+line[1:11]+'0',2)
            print(str(PC) + " : "+type + " rd= 0x" + str(rd) + " imm= " + str(c_int32(imm).value),file=w)
            arr_instruction.append(str(PC) + " : "+type + " rd= 0x" + str(rd) + " imm= " + str(c_int32(imm).value))

        elif(line[25:32]=="1100111"): #JALR
            type='jalr'
            imm=int(line[0]*20+line[0:12],2)
            rs1=int(line[12:17],2)
            funct3=int(line[17:20],2)
            rd=int(line[20:25],2)
            print(str(PC) + " : "+type + " rd= 0x" + str(rd) + " rs1= 0x" + str(rs1) + " imm= " + str(c_int32(imm).value),file=w)
            arr_instruction.append(str(PC) + " : "+type + " rd= 0x" + str(rd) + " rs1= 0x" + str(rs1) + " imm= " + str(c_int32(imm).value))

        elif(line[25:32]=="0110111"): #LUI
            type='lui'
            rd=int(line[20:25],2)
            imm=int(line[0:20]+'0'*12,2)
            print(str(PC) + " : "+type + " rd= 0x" + str(rd) + " imm= " + str(c_int32(imm).value) ,file=w)
            arr_instruction.append(str(PC) + " : "+type + " rd= 0x" + str(rd) + " imm= " + str(c_int32(imm).value))

        elif(line[25:32]=="0010111"): #AUIPC
            type='auipc'
            rd=int(line[20:25],2)
            imm=int(line[0:20]+'0'*12,2)
            print(str(PC) + " : "+type + " rd= 0x" + str(rd) + " imm= " + str(c_int32(imm).value) ,file=w)
            arr_instruction.append(str(PC) + " : "+type + " rd= 0x" + str(rd) + " imm= " + str(c_int32(imm).value))

        else:
            print("unknown instruction")
        PC=PC+4
        arr_type.append(type)
        arr_rd.append(rd)
        arr_rs1.append(rs1)
        arr_rs2.append(rs2)
        arr_imm.append(c_int32(imm).value)


    w.close()
    f.close()
    # print(len(arr_type))
    # print(len(arr_rd))
    # print(len(arr_rs1))
    # print(len(arr_rs2))
    # print(len(arr_imm))
    PC=0
    real_PC=0 #real_PC*4=PC
    reg={0:0}
    mem={0:0}
    count=0
    print(len(arr_instruction))
    while True: #debugger.
        count=count+1
        if(count%10==0): a = input()#한줄씩 실행해보기 위해.
        print(" ")
        if(PC==4*(len(arr_instruction)-1)):
            #끝에 도달해야 종료된다.
            break
        real_PC=int(real_PC)
        if(arr_rs1[real_PC] not in reg):
            reg[arr_rs1[real_PC]]=0
        if(arr_rs2[real_PC] not in reg):
            reg[arr_rs2[real_PC]]=0
        if(reg[arr_rs1[real_PC]]+arr_imm[real_PC] not in mem and (arr_type[real_PC]=="lw" or arr_type[real_PC]=="lh" or arr_type[real_PC]=="lb" or arr_type[real_PC]=="lbu" or arr_type[real_PC]=="lhu")):
            mem[reg[arr_rs1[real_PC]]+arr_imm[real_PC]]=0

        #베릴로그와 달리 딕셔너리는 값이 0으로 초기화되어있지 않으므로, 현재 참조하는 rs1이나 rs2가 reg나 mem에 없는 값이면 0으로 초기화해준다.
        #근데 MEM은 또 rs1이랑 imm의 합이기 때문에 load 관련한 녀석이 아니면 잘못 데이터가 0으로 초기화될 위험이 있다.
        #고로 MEM 초기화는 load 종류인 놈들만 확인하고 초기화한다.
        

        if(arr_type[real_PC]=='add'):
            reg[arr_rd[real_PC]]=reg[arr_rs1[real_PC]]+reg[arr_rs2[real_PC]]
        
        if(arr_type[real_PC]=='sub'):
            reg[arr_rd[real_PC]]=reg[arr_rs1[real_PC]]-reg[arr_rs2[real_PC]]
        
        if(arr_type[real_PC]=='xor'):
            reg[arr_rd[real_PC]]=reg[arr_rs1[real_PC]]^reg[arr_rs2[real_PC]]
        
        if(arr_type[real_PC]=='or'):
            reg[arr_rd[real_PC]]=reg[arr_rs1[real_PC]]|reg[arr_rs2[real_PC]]
        
        if(arr_type[real_PC]=='and'):
            reg[arr_rd[real_PC]]=reg[arr_rs1[real_PC]]&reg[arr_rs2[real_PC]]
        
        if(arr_type[real_PC]=='sll'):
            reg[arr_rd[real_PC]]=reg[arr_rs1[real_PC]]<<reg[arr_rs2[real_PC]]
        
        if(arr_type[real_PC]=='srl'):
            reg[arr_rd[real_PC]]=reg[arr_rs1[real_PC]]>>reg[arr_rs2[real_PC]]
        
        if(arr_type[real_PC]=='sra'):
            reg[arr_rd[real_PC]]=reg[arr_rs1[real_PC]]>>reg[arr_rs2[real_PC]]
        
        if(arr_type[real_PC]=='slt'):
            reg[arr_rd[real_PC]]=reg[arr_rs1[real_PC]]<reg[arr_rs2[real_PC]]
        
        if(arr_type[real_PC]=='sltu'):
            reg[arr_rd[real_PC]]=1 if (reg[arr_rs1[real_PC]]&0xffffffff)<(reg[arr_rs2[real_PC]]&0xffffffff) else 0
        
        if(arr_type[real_PC]=='addi'):
            reg[arr_rd[real_PC]]=reg[arr_rs1[real_PC]]+arr_imm[real_PC]

        if(arr_type[real_PC]=='xori'):
            reg[arr_rd[real_PC]]=reg[arr_rs1[real_PC]]^arr_imm[real_PC]
            
        if(arr_type[real_PC]=='ori'):
            reg[arr_rd[real_PC]]=reg[arr_rs1[real_PC]]|arr_imm[real_PC]
        
        if(arr_type[real_PC]=='andi'):
            reg[arr_rd[real_PC]]=reg[arr_rs1[real_PC]]&arr_imm[real_PC]

        if(arr_type[real_PC]=='slli'):
            reg[arr_rd[real_PC]]=reg[arr_rs1[real_PC]]<<int(bin(arr_imm[real_PC])[-5:],2)

        if(arr_type[real_PC]=='srli'): # srli, srai 등은 원래 imm의 0~5비트만 사용해야 하지만 이 명령은 거의 나오지 않으므로 일단 제쳐둔다.
            reg[arr_rd[real_PC]]=reg[arr_rs1[real_PC]]>>int(bin(arr_imm[real_PC])[-5:],2)

        if(arr_type[real_PC]=='srai'):
            reg[arr_rd[real_PC]]=reg[arr_rs1[real_PC]]>>int(bin(arr_imm[real_PC])[-5:],2)

        if(arr_type[real_PC]=='slti'):
            reg[arr_rd[real_PC]]=1 if(reg[arr_rs1[real_PC]]<arr_imm[real_PC]) else 0

        if(arr_type[real_PC]=='sltiu'):
            reg[arr_rd[real_PC]]=1 if((reg[arr_rs1[real_PC]]&0xffffffff)<(arr_imm[real_PC]&0xffffffff)) else 0

        if(arr_type[real_PC]=='lb'):
            reg[arr_rd[real_PC]]=int(bin(mem[reg[arr_rs1[real_PC]]+arr_imm[real_PC]])[-8:],2)

        if(arr_type[real_PC]=='lh'):
            reg[arr_rd[real_PC]]=int(bin(mem[reg[arr_rs1[real_PC]]+arr_imm[real_PC]])[-16:],2)
        
        if(arr_type[real_PC]=='lw'):
            reg[arr_rd[real_PC]]=mem[reg[arr_rs1[real_PC]]+arr_imm[real_PC]]

        if(arr_type[real_PC]=='lbu'):
            reg[arr_rd[real_PC]]=int(bin(mem[reg[arr_rs1[real_PC]]+arr_imm[real_PC]])[-8:],2)&0xffffffff

        if(arr_type[real_PC]=='lhu'):
            reg[arr_rd[real_PC]]=int(bin(mem[reg[arr_rs1[real_PC]]+arr_imm[real_PC]])[-16:],2)&0xffffffff

        if(arr_type[real_PC]=='sb'):
            mem[reg[arr_rs1[real_PC]]+arr_imm[real_PC]]=int(bin(reg[arr_rs2[real_PC]])[-8:],2)

        if(arr_type[real_PC]=='sh'):
            mem[reg[arr_rs1[real_PC]]+arr_imm[real_PC]]=int(bin(reg[arr_rs2[real_PC]])[-16:],2)

        if(arr_type[real_PC]=='sw'):
            mem[reg[arr_rs1[real_PC]]+arr_imm[real_PC]]=reg[arr_rs2[real_PC]]

        if(arr_type[real_PC]=='beq'):
            if(reg[arr_rs1[real_PC]]==reg[arr_rs2[real_PC]]):
                
                
                print(arr_instruction[real_PC])
                print(reg)
                print(mem)
                PC=PC+arr_imm[real_PC]
                real_PC=PC/4
                continue

        if(arr_type[real_PC]=='bne'):
            if(reg[arr_rs1[real_PC]]!=reg[arr_rs2[real_PC]]):
                
                
                print(arr_instruction[real_PC])
                print(reg)
                print(mem)
                PC=PC+arr_imm[real_PC]
                real_PC=PC/4
                continue

        if(arr_type[real_PC]=='blt'):
            if(reg[arr_rs1[real_PC]]<reg[arr_rs2[real_PC]]):
                
                
                print(arr_instruction[real_PC])
                print(reg)
                print(mem)
                PC=PC+arr_imm[real_PC]
                real_PC=PC/4
                continue

        if(arr_type[real_PC]=='bge'):
            if(reg[arr_rs1[real_PC]]>=reg[arr_rs2[real_PC]]):
                
                
                print(arr_instruction[real_PC])
                print(reg)
                print(mem)
                PC=PC+arr_imm[real_PC]
                real_PC=PC/4
                continue

        if(arr_type[real_PC]=='bltu'):
            if(reg[arr_rs1[real_PC]]<reg[arr_rs2[real_PC]]):
                
                
                print(arr_instruction[real_PC])
                print(reg)
                print(mem)
                PC=PC+arr_imm[real_PC]
                real_PC=PC/4
                continue

        if(arr_type[real_PC]=='bgeu'):
            if(reg[arr_rs1[real_PC]]>=reg[arr_rs2[real_PC]]):
                
                
                print(arr_instruction[real_PC])
                print(reg)
                print(mem)

                PC=PC+arr_imm[real_PC]
                real_PC=PC/4
                continue
        
        if(arr_type[real_PC]=='jal'):
            reg[arr_rd[real_PC]]=PC+4
            reg[0]=0
            
            print(arr_instruction[real_PC])
            print(reg)
            print(mem)
            PC=PC+arr_imm[real_PC]
            real_PC=PC/4
            continue

        if(arr_type[real_PC]=='jalr'):
            reg[arr_rd[real_PC]]=PC+4
            reg[0]=0
            
            
            print(arr_instruction[real_PC])
            print(reg)
            print(mem)
            PC=reg[arr_rs1[real_PC]]+arr_imm[real_PC]
            real_PC=PC/4
            continue

        if(arr_type[real_PC]=='lui'):
            reg[arr_rd[real_PC]]=arr_imm[real_PC]
            reg[0]=0

        if(arr_type[real_PC]=='auipc'):
            reg[arr_rd[real_PC]]=PC+arr_imm[real_PC]
            reg[0]=0
        
        reg[0]=0 # 0은 반드시 0이다.

        print(arr_instruction[real_PC])
        print(reg)
        print(mem)
        
        PC=PC+4
        real_PC=int(PC/4)



# decoder("data/benchmarks/prime_fact")
decoder("data/benchmarks/bst_array")
# decoder("data/benchmarks/fibo")
# decoder("data/benchmarks/matmul")
# decoder("data/benchmarks/quicksort")
# decoder("data/benchmarks/spmv")



